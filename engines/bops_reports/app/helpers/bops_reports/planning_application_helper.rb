# frozen_string_literal: true

module BopsReports
  module PlanningApplicationHelper
    def show_map_pin?(planning_application, data)
      (data[:geojson].blank? || data[:invalid_red_line_boundary].present?) && planning_application.lonlat.present?
    end
  end
end
