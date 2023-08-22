# frozen_string_literal: true

class AddCilLiableToPlanningApplication < ActiveRecord::Migration[7.0]
  def change
    add_column :planning_applications, :cil_liable, :boolean, default: nil, null: true
  end
end
