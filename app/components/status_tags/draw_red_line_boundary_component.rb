# frozen_string_literal: true

module StatusTags
  class DrawRedLineBoundaryComponent < StatusTags::BaseComponent
    def initialize(boundary_geojson:)
      @boundary_geojson = boundary_geojson
      super(status:)
    end

    private

    attr_reader :boundary_geojson

    def status
      boundary_geojson.present? ? :complete : :not_started
    end
  end
end
