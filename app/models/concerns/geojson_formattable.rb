# frozen_string_literal: true

module GeojsonFormattable
  extend ActiveSupport::Concern

  class_methods do
    def format_geojson_epsg(column_name)
      define_method(column_name) do
        original = super()
        return if original.blank?
        return original if original.is_a?(Hash)

        parsed = JSON.parse(original)
        geojson_hash = parsed["EPSG:3857"] || parsed

        geojson_hash.to_json
      end
    end
  end
end
