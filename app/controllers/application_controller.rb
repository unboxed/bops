# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :find_current_local_authority_from_subdomain
  before_action :prevent_caching
  before_action :set_current_user
  before_action :enforce_user_permissions
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_back_path

  attr_reader :current_local_authority

  helper_method :current_local_authority

  def after_sign_in_path_for(resource)
    if session[:mobile_number] && !resource.mobile_number?
      resource.assign_mobile_number!(session[:mobile_number])
      session.delete(:mobile_number)
    end

    respond_to do |format|
      format.html do
        flash[:notice] = t("devise.sessions.signed_in")
        super
      end
    end
  end

  protected

  def set_planning_application
    application = planning_applications_scope.find(planning_application_id)
    @planning_application = PlanningApplicationPresenter.new(view_context, application)
  end

  def planning_applications_scope
    current_local_authority.planning_applications
  end

  def planning_application_id
    if request.path_parameters.key?(:planning_application_id)
      Integer(params[:planning_application_id].to_s)
    else
      Integer(params[:id].to_s)
    end
  end

  def set_consultation
    if @planning_application.application_type.steps.include? "consultation"
      if @planning_application.consultation.nil?
        error = <<~ERROR
          "Couldn't find consultation with 'planning_application_id'=#{@planning_application_id}"
        ERROR

        raise ActiveRecord::RecordNotFound, error
      end

      @consultation = @planning_application.consultation
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end

  private

  def set_back_path
    session[:back_path] = request.referer if request.get?
    @back_path = session[:back_path]
  end

  def find_current_local_authority_from_subdomain
    return if @current_local_authority ||= LocalAuthority.find_by(subdomain: request.subdomains.first)

    render plain: "No Local Authority Found", status: :not_found
  end

  def prevent_caching
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = 0
  end

  def set_current_user
    Current.user = current_user
  end

  def enforce_user_permissions
    redirect_to administrator_dashboard_path if current_user&.administrator?
  end

  def ensure_user_is_reviewer
    render plain: "forbidden", status: :forbidden and return unless Current.user.reviewer?
  end

  def ensure_user_is_reviewer_checking_assessment
    render plain: "forbidden", status: :forbidden and return unless @planning_application.can_review_assessment?
  end
end
