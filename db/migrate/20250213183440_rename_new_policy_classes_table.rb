# frozen_string_literal: true

class RenameNewPolicyClassesTable < ActiveRecord::Migration[7.2]
  def change
    safety_assured do
      rename_table :new_policy_classes, :policy_classes
    end
  end
end
