class AddPreviousDescriptionToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :previous_description, :string
  end
end
