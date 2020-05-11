class AddColumnToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :ward, :string
  end
end
