# frozen_string_literal: true

module ReturnToReport
  extend ActiveSupport::Concern

  private

  def store_return_to_report_path
    return unless params[:return_to] == "report"
    return unless @planning_application.pre_application?

    session[:return_to_report_paths] ||= {}
    session[:return_to_report_paths][@planning_application.reference] = true
  end

  def report_path_or(default_path)
    if session.dig(:return_to_report_paths, @planning_application.reference)
      session[:return_to_report_paths].delete(@planning_application.reference)
      bops_reports.planning_application_path(@planning_application)
    else
      default_path
    end
  end
end
