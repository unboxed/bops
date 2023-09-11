# frozen_string_literal: true

class AddNeighbourResponseIdToDocument < ActiveRecord::Migration[7.0]
  def change
    add_reference :documents, :neighbour_response, null: true, foreign_key: true
  end
end
