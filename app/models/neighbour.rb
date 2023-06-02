# frozen_string_literal: true

class Neighbour < ApplicationRecord
  belongs_to :consultation
  has_one :neighbour_letter, dependent: :destroy

  validates :address, presence: true

  scope :without_letters, -> { left_outer_joins(:neighbour_letter).where(neighbour_letter: { neighbour_id: nil }) }
  scope :with_letters, lambda {
                         includes([:neighbour_letter])
                           .joins(:neighbour_letter)
                           .where.not(neighbour_letter: { neighbour_id: nil })
                       }
end
