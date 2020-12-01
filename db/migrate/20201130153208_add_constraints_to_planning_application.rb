class AddConstraintsToPlanningApplication < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :constraints, :jsonb
    remove_reference :planning_applications, :agent
    remove_reference :planning_applications, :applicant
  end
end
