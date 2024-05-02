# frozen_string_literal: true

module Validation
  class CheckRedLineBoundaryTask < WorkflowTask
    def task_list_status
      if planning_application.valid_red_line_boundary? || red_line_boundary_change_request&.approved?
        :complete
      elsif planning_application.red_line_boundary_change_validation_requests.open_or_pending.any?
        :invalid
      elsif red_line_boundary_change_request&.approved == false
        :updated
      else
        :not_started
      end
    end

    def task_list_link_text
      I18n.t("task_list_items.check_red_line_boundary_component.check_red_line")
    end

    def task_list_link
      return if planning_application.boundary_geojson.blank?

      if task_list_status == :not_started ||
          (task_list_status == :complete && planning_application.red_line_boundary_change_validation_requests.closed.none?)
        planning_application_validation_sitemap_path(planning_application)
      else
        planning_application_validation_red_line_boundary_change_validation_request_path(
          planning_application,
          red_line_boundary_change_request
        )
      end
    end

    private

    def red_line_boundary_change_request
      planning_application.red_line_boundary_change_validation_requests
        .not_cancelled
        .order(:created_at)
        .last
    end
  end
end
