class AddBoundaryCreatedByToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_reference :planning_applications, :boundary_created_by, references: :users, foreign_key: { to_table: :users }
  end
end
