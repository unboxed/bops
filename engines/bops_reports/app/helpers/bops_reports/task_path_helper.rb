# frozen_string_literal: true

module BopsReports
  module TaskPathHelper
    def report_task_path(planning_application, slug_path, anchor: nil)
      bops_preapps.task_path(
        reference: planning_application.reference,
        slug: slug_path,
        return_to: report_return_path(planning_application, anchor: anchor)
      )
    end

    private

    def report_return_path(planning_application, anchor: nil)
      path = planning_application_path(planning_application)
      anchor ? "#{path}##{anchor}" : path
    end
  end
end
