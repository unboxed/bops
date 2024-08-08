# frozen_string_literal: true

class CreatePolicyParts < ActiveRecord::Migration[7.1]
  def change
    create_table :policy_parts do |t|
      t.integer :number, null: false
      t.string :name, null: false
      t.references :policy_schedule, null: false, foreign_key: true

      t.timestamps
    end

    add_index :policy_parts, [:number, :policy_schedule_id], unique: true
  end
end
