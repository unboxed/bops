# frozen_string_literal: true

class CreatePolicySection < ActiveRecord::Migration[7.1]
  def change
    create_table :policy_sections do |t|
      t.string :section, null: false
      t.text :description, null: false
      t.references :new_policy_class, null: false, foreign_key: true

      t.timestamps
    end

    add_index :policy_sections, [:section, :new_policy_class_id], unique: true
  end
end
