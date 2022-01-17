# frozen_string_literal: true

class AddClosedAtToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :closed_at, :datetime
  end
end
