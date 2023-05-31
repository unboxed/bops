# frozen_string_literal: true

class Neighbour < ApplicationRecord
  belongs_to :consultation
  has_one :neighbour_letter, dependent: :destroy

  validates :address, presence: true
end
