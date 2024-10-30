# frozen_string_literal: true

class NeighbourLetterStatusUpdateJob < ApplicationJob
  def perform(consultation)
    letters = consultation.neighbour_letters.includes(:neighbour).where.not(status: "received")

    letters.each do |letter|
      letter.update_status
    end
  end
end
