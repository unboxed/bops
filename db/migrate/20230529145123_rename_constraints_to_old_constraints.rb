# frozen_string_literal: true

class RenameConstraintsToOldConstraints < ActiveRecord::Migration[7.0]
  def change
    rename_column :planning_applications, :constraints, :old_constraints
  end
end
