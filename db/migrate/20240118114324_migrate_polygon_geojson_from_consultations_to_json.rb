# frozen_string_literal: true

class MigratePolygonGeojsonFromConsultationsToJson < ActiveRecord::Migration[7.0]
  def change
    up_only do
      Consultation.find_each do |co|
        polygon_geojson = co.read_attribute(:polygon_geojson)
        next if polygon_geojson.blank?

        if polygon_geojson.is_a?(String)
          begin
            parsed_json = JSON.parse(polygon_geojson)["EPSG:3857"]
            co.update_column(:polygon_geojson, parsed_json)
          rescue JSON::ParserError
          end
        end
      end
    end
  end
end
