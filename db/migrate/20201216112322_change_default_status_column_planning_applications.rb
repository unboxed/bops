# frozen_string_literal: true

class ChangeDefaultStatusColumnPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    change_column :planning_applications, :status, :string, default: "not_started", null: false
  end
end
