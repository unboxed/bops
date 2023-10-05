# frozen_string_literal: true

class ChangePolicyAreaToLocalPolicy < ActiveRecord::Migration[7.0]
  def change
    rename_table :policy_areas, :local_policies
    rename_table :considerations, :local_policy_areas
    rename_table :review_policy_areas, :review_local_policies

    remove_reference :review_local_policies, :policy_area
    remove_reference :local_policy_areas, :policy_area
    add_reference :review_local_policies, :local_policy, foreign_key: true
    add_reference :local_policy_areas, :local_policy, foreign_key: true
  end
end
