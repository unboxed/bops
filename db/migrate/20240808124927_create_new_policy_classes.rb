# frozen_string_literal: true

class CreateNewPolicyClasses < ActiveRecord::Migration[7.1]
  def change
    create_table :new_policy_classes do |t|
      t.string :section, null: false
      t.string :name, null: false
      t.string :url
      t.references :policy_part, null: false, foreign_key: true

      t.timestamps
    end

    add_index :new_policy_classes, [:section, :policy_part_id], unique: true
  end
end
