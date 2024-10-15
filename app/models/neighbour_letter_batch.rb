# frozen_string_literal: true

class NeighbourLetterBatch < ApplicationRecord
  belongs_to :consultation
  has_many :neighbour_letters, dependent: :destroy, inverse_of: :batch
end
