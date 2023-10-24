# frozen_string_literal: true

class ProposalMeasurement < ApplicationRecord
  belongs_to :planning_application

  validates :depth, :max_height, :eaves_height, numericality: {only_float: true}
end
