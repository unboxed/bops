# frozen_string_literal: true

class AddConsultationToNeighbourResponse < ActiveRecord::Migration[7.0]
  class NeighbourResponse < ApplicationRecord
    belongs_to :neighbour
  end

  def change
    add_reference :neighbour_responses, :consultation, foreign_key: true
    NeighbourResponse.find_each do |response|
      next if response.neighbour.nil?

      response.consultation_id = response.neighbour.consultation.id
      response.save
    end
  end
end
