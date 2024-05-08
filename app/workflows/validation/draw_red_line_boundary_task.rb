# frozen_string_literal: true

module Validation
  class DrawRedLineBoundaryTask < WorkflowTask
    def task_list_link_text
      "Draw red line boundary"
    end

    def task_list_link
      return unless !(planning_application.boundary_geojson.present? && planning_application.officer_can_draw_boundary?)

      planning_application_validation_sitemap_path(planning_application)
    end

    def task_list_status
      planning_application.boundary_geojson.present? ? :complete : :not_started
    end
  end
end
