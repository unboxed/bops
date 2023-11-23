# frozen_string_literal: true

class AddMissingNeighbourForeignKeyToNeighbourLetters < ActiveRecord::Migration[7.0]
  def change
    up_only do
      execute <<~SQL
        DELETE FROM neighbour_letters
        WHERE neighbour_id NOT IN (SELECT id FROM neighbours)
      SQL
    end

    add_foreign_key :neighbour_letters, :neighbours
  end
end
