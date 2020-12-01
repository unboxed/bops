class AddNotStartedToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :not_started_at, :datetime, null: true
  end
end
