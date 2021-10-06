# frozen_string_literal: true

class CreateDescriptionChangeRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :description_change_requests do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :state, default: "open", null: false
      t.text :proposed_description
      t.boolean :approved
      t.string :rejection_reason

      t.timestamps
    end
  end
end
