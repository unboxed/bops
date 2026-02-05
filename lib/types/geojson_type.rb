# frozen_string_literal: true

class GeojsonType < ActiveModel::Type::Value
  include ActiveModel::Type::Helpers::Mutable

  JSON_ENCODER = ActiveSupport::JSON::Encoding.json_encoder.new(escape: false)

  def type
    :geojson
  end

  def deserialize(value)
    return value unless value.is_a?(String)
    return nil if value == %("null")

    begin
      ActiveSupport::JSON.decode(value)
    rescue JSON::ParserError
      nil
    end
  end

  def serialize(value)
    JSON_ENCODER.encode(value) unless value.nil?
  end

  def changed_in_place?(raw_old_value, new_value)
    deserialize(raw_old_value) != new_value
  end
end
