# frozen_string_literal: true

class CreateNeighbourResponse < ActiveRecord::Migration[7.0]
  def change
    create_table :neighbour_responses do |t|
      t.references :neighbour
      t.string :name
      t.string :response
      t.string :email
      t.datetime :received_at
      t.timestamps
    end

    remove_column :neighbours, :name, :string
  end
end
