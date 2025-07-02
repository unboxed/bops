# frozen_string_literal: true

class Address < Struct.new(
  :line_1,
  :line_2,
  :town,
  :county,
  :postcode
)
end
