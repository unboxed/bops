class AddStatusColumnsToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :invalidated_at, :datetime
    add_column :planning_applications, :withdrawn_at, :datetime
    add_column :planning_applications, :returned_at, :datetime
  end
end
