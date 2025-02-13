# frozen_string_literal: true

class RenameNewPolicyClassIdColumn < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      rename_column :planning_application_policy_classes, :new_policy_class_id, :policy_class_id
      rename_column :policy_sections, :new_policy_class_id, :policy_class_id
    end
  end
end
