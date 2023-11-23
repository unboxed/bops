# frozen_string_literal: true

class AddMissingPlanningApplicationForeignKeyToLocalPolicies < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :local_policies, :planning_applications
  end
end
