class AddWarnTypeToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :ward_type_name, :string
  end
end
