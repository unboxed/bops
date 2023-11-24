# frozen_string_literal: true

class DropOldConstraintsFromPlanningApplications < ActiveRecord::Migration[7.0]
  def change
    remove_column :planning_applications, :old_constraints, :text
  end
end
