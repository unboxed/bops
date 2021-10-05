# frozen_string_literal: true

class RenameCompletedAtToDeterminedAtOnPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    rename_column :planning_applications, :completed_at, :determined_at
  end
end
