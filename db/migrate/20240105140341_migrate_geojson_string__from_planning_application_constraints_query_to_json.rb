# frozen_string_literal: true

class MigrateGeojsonStringFromPlanningApplicationConstraintsQueryToJson < ActiveRecord::Migration[7.0]
  def change
    up_only do
      PlanningApplicationConstraintsQuery.find_each do |pa|
        geojson = pa.read_attribute(:geojson)
        next if geojson.blank?

        if geojson.is_a?(String)
          begin
            parsed_json = JSON.parse(geojson)
            pa.update_column(:geojson, parsed_json)
          rescue JSON::ParserError
          end
        end
      end
    end
  end
end
