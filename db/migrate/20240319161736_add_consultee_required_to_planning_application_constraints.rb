class AddConsulteeRequiredToPlanningApplicationConstraints < ActiveRecord::Migration[7.1]
  def change
    add_column :planning_application_constraints, :consultee_required, :boolean
  end
end
