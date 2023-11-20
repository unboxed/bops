# frozen_string_literal: true

class AddPendingAtToPlanningApplications < ActiveRecord::Migration[7.0]
  def change
    add_column :planning_applications, :pending_at, :datetime
  end
end
