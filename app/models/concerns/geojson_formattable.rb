# frozen_string_literal: true

module GeojsonFormattable
  extend ActiveSupport::Concern

  class_methods do
    def format_geojson_epsg(column_name, set_type: false)
      define_method(column_name) do
        original = super()
        return if original.blank?
        return original if original.is_a?(Hash)

        parsed = JSON.parse(original)
        geojson_hash = parsed["EPSG:3857"] || parsed

        update_geojson_properties(geojson_hash, column_name) if set_type

        geojson_hash.to_json
      end
    end
  end

  private

  def update_geojson_properties(geojson_hash, column_name)
    # Set the column type for each feature properties
    if geojson_hash["type"] == "FeatureCollection"
      geojson_hash["features"].each { |feature| set_geojson_properties(feature, column_name) }
    else
      set_geojson_properties(geojson_hash, column_name)
    end
  end

  def set_geojson_properties(geojson_hash, column_name)
    geojson_hash["properties"] ||= {}
    geojson_hash["properties"]["type"] = column_name.to_s
  end
end
