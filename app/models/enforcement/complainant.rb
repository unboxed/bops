# frozen_string_literal: true

class Enforcement::Complainant < ApplicationRecord
  belongs_to :enforcement

  composed_of :address,
    mapping: {
      address_1: :line_1,
      address_2: :line_2,
      town: :town,
      county: :county,
      postcode: :postcode
    }

  def name
    [first_name, last_name].compact_blank.join(" ")
  end

  def full_address
    address.to_s
  end
end
