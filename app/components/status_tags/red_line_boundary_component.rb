# frozen_string_literal: true

module StatusTags
  class RedLineBoundaryComponent < StatusTags::BaseComponent
    def initialize(boundary_geojson:)
      @boundary_geojson = boundary_geojson
    end

    private

    attr_reader :boundary_geojson

    def status
      boundary_geojson.present? ? :checked : :not_checked_yet
    end
  end
end
