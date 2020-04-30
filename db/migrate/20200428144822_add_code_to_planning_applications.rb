class AddCodeToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :code, :string
  end
end
