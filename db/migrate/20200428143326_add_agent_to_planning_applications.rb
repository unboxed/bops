class AddAgentToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_reference :planning_applications, :agent, null: true
  end
end
