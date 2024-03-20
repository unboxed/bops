# frozen_string_literal: true

class AddConsulteesCheckedToPlanningApplication < ActiveRecord::Migration[7.1]
  def change
    add_column :planning_applications, :consultees_checked, :boolean, default: false, null: false
  end
end
