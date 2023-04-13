# frozen_string_literal: true

class AddChangedConstraintsToPlanningApplication < ActiveRecord::Migration[7.0]
  def change
    add_column :planning_applications, :changed_constraints, :text, array: true
  end
end
