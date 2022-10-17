# frozen_string_literal: true

class CreateConsultees < ActiveRecord::Migration[6.1]
  def change
    create_table :consultees do |t|
      t.string :name, null: false
      t.integer :origin, null: false
      t.references :planning_application
      t.timestamps
    end
  end
end
