# frozen_string_literal: true

class RemovePolicyClassesBak < ActiveRecord::Migration[6.1]
  def change
    remove_column(
      :planning_applications,
      :policy_classes_bak,
      :jsonb,
      default: [],
      array: true
    )
  end
end
