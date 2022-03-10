# frozen_string_literal: true

class AddConstraintsCheckedToPlanningApplication < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :constraints_checked, :boolean, null: false, default: false
  end
end
