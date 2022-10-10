# frozen_string_literal: true

class RedLineBoundaryStatusTagComponent < StatusTagComponent
  def initialize(boundary_geojson:)
    @boundary_geojson = boundary_geojson
  end

  private

  attr_reader :boundary_geojson

  def status
    boundary_geojson.present? ? :checked : :not_checked_yet
  end
end
