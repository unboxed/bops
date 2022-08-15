# frozen_string_literal: true

class AddReceivedAtToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :received_at, :datetime
  end
end
