# frozen_string_literal: true

class Address < Struct.new(
  :line_1,
  :line_2,
  :town,
  :county,
  :postcode
)
  def blank?
    attributes.none?(&:present?)
  end

  def to_s
    attributes.compact_blank.join(", ")
  end

  def as_json(*)
    to_s
  end

  alias_method :to_json, :as_json
  alias_method :to_str, :to_s

  private

  def attributes
    [
      line_1,
      line_2,
      town,
      county,
      postcode&.gsub(/\s+/, "\u00A0") # non-breaking space
    ]
  end
end
