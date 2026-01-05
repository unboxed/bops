# frozen_string_literal: true

module ReturnToReport
  extend ActiveSupport::Concern

  RETURN_TO_REPORT = "report"

  included do
    helper_method :return_to_path, :return_to_param
  end

  private

  def return_to_path(default_path = nil)
    resolve_return_to(return_to_param) || default_path || default_tasks_path
  end

  def return_to_param
    params[:return_to].presence ||
      params[:redirect_to].presence ||
      params.dig(controller_name.singularize.to_sym, :return_to).presence
  end

  def resolve_return_to(value)
    case value
    when RETURN_TO_REPORT
      bops_reports.planning_application_path(@planning_application) if @planning_application&.pre_application?
    when /\A\//
      value
    end
  end

  def default_tasks_path
    if controller_path.include?("validation")
      planning_application_validation_tasks_path(@planning_application)
    else
      planning_application_assessment_tasks_path(@planning_application)
    end
  end
end
