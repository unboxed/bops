# frozen_string_literal: true

class AddMissingNeighbourForeignKeyToNeighbourResponses < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :neighbour_responses, :neighbours
  end
end
