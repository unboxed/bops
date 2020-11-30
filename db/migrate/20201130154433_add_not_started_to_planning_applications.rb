class AddNotStartedToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :not_started_at, :datetime, null: true
    add_column :planning_applications, :document_status, :integer, default: 0
  end
end
