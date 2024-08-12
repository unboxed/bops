# frozen_string_literal: true

class CreatePlanningApplicationPolicySections < ActiveRecord::Migration[7.1]
  def change
    create_table :planning_application_policy_sections do |t|
      t.string :status
      t.references :planning_application, null: false, foreign_key: true
      t.references :policy_section, null: false, foreign_key: true

      t.timestamps
    end
  end
end
