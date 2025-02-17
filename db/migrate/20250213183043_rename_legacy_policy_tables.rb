# frozen_string_literal: true

class RenameLegacyPolicyTables < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      rename_table :policy_classes, :old_policy_classes
      rename_table :policies, :old_policies
    end
  end
end
