# frozen_string_literal: true

class RenameNewPolicyClassIndex < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      rename_index :planning_application_policy_classes,
        "ix_pa_policy_classes_on_new_policy_class_and_pa",
        "ix_pa_policy_classes_on_policy_class_and_pa"
    end
  end
end
