# frozen_string_literal: true

class AddOriginalGeoJsonToRedLineBoundaryChangeValidationRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :red_line_boundary_change_validation_requests, :original_geojson, :json
  end
end
