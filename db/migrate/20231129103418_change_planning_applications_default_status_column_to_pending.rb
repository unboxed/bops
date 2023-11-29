# frozen_string_literal: true

class ChangePlanningApplicationsDefaultStatusColumnToPending < ActiveRecord::Migration[7.0]
  def up
    change_column :planning_applications, :status, :string, default: "pending", null: false
  end

  def down
    change_column :planning_applications, :status, :string, default: "not_started", null: false
  end
end
