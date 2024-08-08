# frozen_string_literal: true

class CreatePlanningApplicationPolicyClasses < ActiveRecord::Migration[7.1]
  def change
    create_table :planning_application_policy_classes do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :new_policy_class, null: false, foreign_key: true

      t.timestamps
    end
  end
end
