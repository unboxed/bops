# frozen_string_literal: true

class AddNeighbourLetterTextToConsultation < ActiveRecord::Migration[7.0]
  def change
    add_column :consultations, :neighbour_letter_text, :string
  end
end
