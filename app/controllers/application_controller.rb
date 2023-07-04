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
        flash[:notice] = "Signed in successfully."
        super
      end
    end
  end

  protected

  def set_planning_application
    application = current_local_authority
                  .planning_applications
                  .find(params[:planning_application_id] || params[:id])

    @planning_application = PlanningApplicationPresenter.new(view_context, application)
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
    response.headers["Expires"] = 100.years.ago
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
