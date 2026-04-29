# frozen_string_literal: true

class AuthenticationController < ApplicationController
  class_attribute :application_section

  before_action :authenticate_user!

  rescue_from ActionController::InvalidAuthenticityToken, with: :reset_session_and_redirect

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

  def redirect_to_initial_task
    return unless use_new_sidebar_layout?(@planning_application)

    task = @planning_application.case_record.tasks.find_by(section: application_section)&.first_child

    return unless task

    redirect_to task.url
  end
end
