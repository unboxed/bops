# frozen_string_literal: true

module BopsEnforcements
  module ApplicationHelper
    include BopsCore::ApplicationHelper
    include BreadcrumbNavigationHelper

    def home_path
      root_path
    end

    def show_map_pin?(enforcement, data)
      (data[:geojson].blank? || data[:invalid_red_line_boundary].present?) && enforcement.lonlat.present?
    end
  end
end
