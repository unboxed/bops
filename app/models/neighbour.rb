# frozen_string_literal: true

class Neighbour < ApplicationRecord
  belongs_to :consultation

  validates :address, presence: true
end
