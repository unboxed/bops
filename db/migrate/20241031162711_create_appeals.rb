# frozen_string_literal: true

class CreateAppeals < ActiveRecord::Migration[7.1]
  def change
    create_table :appeals do |t|
      t.text :reason, null: false
      t.string :status, null: false, default: "lodged"
      t.string :decision
      t.datetime :lodged_at, null: false
      t.datetime :validated_at
      t.datetime :started_at
      t.datetime :determined_at
      t.references :planning_application, null: false, foreign_key: true

      t.timestamps
    end
  end
end
