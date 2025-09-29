# frozen_string_literal: true

class Address < Struct.new(
  :line_1,
  :line_2,
  :town,
  :county,
  :postcode
)
  def to_s
    [
      line_1,
      line_2,
      town,
      county,
      postcode.gsub(/\s+/, "\u00A0") # non-breaking space
    ].compact_blank.join(", ")
  end
end
