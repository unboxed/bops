# frozen_string_literal: true

class MigrateBoundaryGeojsonStringFromPlanningApplicationToJson < ActiveRecord::Migration[7.0]
  def change
    up_only do
      PlanningApplication.find_each do |pa|
        boundary_geojson = pa.read_attribute(:boundary_geojson)
        next if boundary_geojson.blank?

        if boundary_geojson.is_a?(String)
          begin
            parsed_json = JSON.parse(boundary_geojson)
            pa.update_column(:boundary_geojson, parsed_json)
          rescue JSON::ParserError
          end
        end
      end
    end
  end
end
