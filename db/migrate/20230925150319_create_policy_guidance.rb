# frozen_string_literal: true

class CreatePolicyGuidance < ActiveRecord::Migration[7.0]
  def change
    create_table :policy_guidances do |t|
      t.text :policies
      t.text :assessment
      t.references :planning_application, null: false
      t.timestamps
    end
  end
end
