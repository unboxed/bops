# frozen_string_literal: true

class FixDoubleSerializedPolygonGeojson < ActiveRecord::Migration[8.0]
  def change
    up_only do
      Consultation.find_each do |consultation|
        polygon_geojson = consultation.read_attribute(:polygon_geojson)
        next if polygon_geojson.blank?

        if polygon_geojson.is_a?(String)
          begin
            parsed_json = JSON.parse(polygon_geojson)
            consultation.update_column(:polygon_geojson, parsed_json)
          rescue JSON::ParserError
          end
        end
      end
    end
  end
end
