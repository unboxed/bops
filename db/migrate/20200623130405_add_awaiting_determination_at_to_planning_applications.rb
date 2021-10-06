# frozen_string_literal: true

class AddAwaitingDeterminationAtToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :awaiting_determination_at, :datetime, null: true
  end
end
