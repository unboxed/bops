# frozen_string_literal: true

class AddMissingLocalPolicyClassForeignKeyToPolicies < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :policies, :policy_classes
  end
end
