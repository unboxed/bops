class AddCompletedToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :work_status, :string, default: "Proposed"
  end
end
