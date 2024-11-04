# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include BopsCore::ApplicationController

  before_action :require_local_authority!
  before_action :prevent_caching
  before_action :enforce_user_permissions
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_back_path

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

  def get_planning_application(param)
    if param.match?(/[a-z]/i)
      planning_applications_scope.find_by!(reference: param)
    else
      planning_applications_scope.find(planning_application_id)
    end
  end

  def set_planning_application
    param = params[planning_application_param]
    application = get_planning_application(param)

    @planning_application = PlanningApplicationPresenter.new(view_context, application)
  end

  def redirect_to_reference_url
    param = params[planning_application_param]
    return if param.match?(/[a-z]/i)
    planning_application = get_planning_application(param)

    redirect_to request.env["PATH_INFO"].gsub(%r{/#{planning_application.id}}, "/#{planning_application.reference}")
  end

  def planning_applications_scope
    current_local_authority.planning_applications.accepted
  end

  def planning_application_param
    request.path_parameters.key?(:planning_application_reference) ? :planning_application_reference : :reference
  end

  def planning_application_id
    Integer(params[planning_application_param])
  rescue ArgumentError
    raise ActionController::BadRequest, "Invalid planning application id: #{params[planning_application_param].inspect}"
  end

  def set_consultation
    if @planning_application.consultation.nil?
      error = <<~ERROR
        "Couldn't find consultation with 'planning_application_id'=#{@planning_application_id}"
      ERROR

      raise ActiveRecord::RecordNotFound, error
    end

    @consultation = @planning_application.consultation
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt, :subdomain])
  end

  private

  def prevent_caching
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = 0
  end

  def enforce_user_permissions
    redirect_to bops_admin.dashboard_url if current_user&.administrator?
  end

  def ensure_user_is_reviewer
    render plain: "forbidden", status: :forbidden and return unless Current.user.reviewer?
  end

  def ensure_user_is_reviewer_checking_assessment
    render plain: "forbidden", status: :forbidden and return unless @planning_application.can_review_assessment?
  end
end
