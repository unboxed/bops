# frozen_string_literal: true

class AddRemovalToPlanningApplicationConstraints < ActiveRecord::Migration[7.0]
  def change
    add_column :planning_application_constraints, :removed_at, :datetime, null: true
  end
end
