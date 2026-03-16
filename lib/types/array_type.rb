# frozen_string_literal: true

class ArrayType < ActiveModel::Type::Value
  attr_reader :subtype
  attr_reader :allow_blank

  def initialize(type: :string, allow_blank: false)
    super()

    @subtype = type
    @allow_blank = allow_blank
  end

  def type
    :array
  end

  def cast(value)
    Array(value).each_with_object([]) do |item, items|
      next if item.blank? && !allow_blank
      items << cast_subtype(item)
    end
  end

  private

  def cast_subtype(value)
    case subtype
    when :string
      value.to_s
    when :integer
      value.to_i
    else
      raise ArgumentError, "Unexpected subtype value for array type: #{subtype.inspect}"
    end
  end
end
