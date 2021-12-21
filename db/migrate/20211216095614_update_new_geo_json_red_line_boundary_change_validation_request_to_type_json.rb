# frozen_string_literal: true

class UpdateNewGeoJsonRedLineBoundaryChangeValidationRequestToTypeJson < ActiveRecord::Migration[6.1]
  def up
    change_column :red_line_boundary_change_validation_requests, :new_geojson, :json, using: "CAST(new_geojson AS JSON)"
  end

  def down
    change_column :red_line_boundary_change_validation_requests, :new_geojson, :string
  end
end
