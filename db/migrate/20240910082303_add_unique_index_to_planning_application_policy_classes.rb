# frozen_string_literal: true

class AddUniqueIndexToPlanningApplicationPolicyClasses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :planning_application_policy_classes, [:new_policy_class_id, :planning_application_id], unique: true, algorithm: :concurrently, name: "ix_pa_policy_classes_on_new_policy_class_and_pa"
  end
end
