# frozen_string_literal: true

class AuthenticationController < ApplicationController
  before_action :authenticate_user!

  rescue_from ActionController::InvalidAuthenticityToken, with: :reset_session_and_redirect

  def user_not_authorized(_error, message = t("user_not_authorized"))
    respond_to do |format|
      format.html { redirect_to pundit_redirect_url, alert: message }
      format.json { render json: [message], status: :unauthorized }
    end
  end

  private

  def ensure_planning_application_is_not_preapp
    return unless @planning_application.pre_application?

    if @planning_application.in_assessment?
      redirect_to planning_application_assessment_tasks_path(@planning_application),
        alert: t("planning_applications.assessment.base.not_preapp", application_type: @planning_application.application_type.full_name)
    else
      redirect_to planning_application_path(@planning_application),
        alert: t("planning_applications.assessment.base.not_preapp", application_type: @planning_application.application_type.full_name)
    end
  end
end
