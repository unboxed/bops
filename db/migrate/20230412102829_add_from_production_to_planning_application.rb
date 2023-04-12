# frozen_string_literal: true

class AddFromProductionToPlanningApplication < ActiveRecord::Migration[7.0]
  def change
    add_column :planning_applications, :from_production, :boolean, default: false
  end
end
