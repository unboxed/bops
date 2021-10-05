# frozen_string_literal: true

class OtherChangeValidationRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :other_change_validation_requests do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :state, default: "open", null: false
      t.text :summary
      t.text :suggestion
      t.text :response
      t.integer :sequence

      t.timestamps
    end
  end
end
