# frozen_string_literal: true

class Enforcement::Complainant < ApplicationRecord
  belongs_to :enforcement

  validates :first_name, :last_name, presence: true
  validates :email, presence: true, if: -> { postcode.blank? }
  validates :address_1, :postcode, presence: true, if: -> { email.blank? || address_1.present? || postcode.present? }

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
