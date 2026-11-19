# frozen_string_literal: true

class Enforcement::InterestedParty < ApplicationRecord
  belongs_to :enforcement

  RELATIONSHIPS = %i[
    owner
    occupier
    tenant
    other
  ].freeze
  enum :relationship, RELATIONSHIPS.index_with(&:to_s)

  composed_of :address,
    mapping: {
      address_1: :line_1,
      address_2: :line_2,
      town: :town,
      county: :county,
      postcode: :postcode
    }

  validates :relationship, presence: true
  validates :other_relationship, presence: true, if: -> { relationship == "other" }
end
