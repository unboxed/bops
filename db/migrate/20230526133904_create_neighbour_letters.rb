# frozen_string_literal: true

class CreateNeighbourLetters < ActiveRecord::Migration[7.0]
  def change
    create_table :neighbour_letters do |t|
      t.references :neighbour, null: false
      t.string :text
      t.string :sent_at
      t.json :notify_response

      t.timestamps
    end
  end
end
