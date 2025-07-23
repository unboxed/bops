# frozen_string_literal: true

module BopsReports
  module PlanningApplicationHelper
    def show_map_pin?(planning_application, data)
      (data[:geojson].blank? || data[:invalid_red_line_boundary].present?) && planning_application.lonlat.present?
    end

    def applicant_view?
      current_user.nil? || params[:view_as] == "applicant"
    end

    def editing_enabled?
      current_user.present? &&
        !applicant_view? &&
        !@planning_application.determined?
    end
  end
end
