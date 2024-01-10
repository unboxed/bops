# frozen_string_literal: true

class MigrateSpecificAttributesStringFromRedLineBoundaryValidationRequestsToJson < ActiveRecord::Migration[7.0]
  def change
    up_only do
      ValidationRequest.red_line_boundary_changes.find_each do |vr|
        new_geojson_value = vr.read_attribute(:specific_attributes)["new_geojson"]
        original_geojson_value = vr.read_attribute(:specific_attributes)["original_geojson"]

        next if new_geojson_value.blank? || original_geojson_value.blank?

        if new_geojson_value.is_a?(String) || original_geojson_value.is_a?(String)
          begin
            vr.specific_attributes["new_geojson"] = JSON.parse(new_geojson_value) if new_geojson_value.is_a?(String)
            vr.specific_attributes["original_geojson"] = JSON.parse(original_geojson_value) if original_geojson_value.is_a?(String)

            vr.update_column(:specific_attributes, vr.specific_attributes)
          rescue JSON::ParserError
          end
        end
      end
    end
  end
end
