# frozen_string_literal: true

class CreateNeighbourLetterBatches < ActiveRecord::Migration[7.1]
  def change
    create_table :neighbour_letter_batches do |t|
      t.references :consultation, foreign_key: true
      t.string :text

      t.timestamps
    end

    safety_assured {
      change_table :neighbour_letters, bulk: true do |t|
        t.references :batch, foreign_key: {to_table: :neighbour_letter_batches}
      end
    }
  end
end
