class AddLocalPlanningAuthorityToRelevantModels < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :local_planning_authority_id, :integer
    add_index  :users, :local_planning_authority_id
    add_column :planning_applications, :local_planning_authority_id, :integer
    add_index  :planning_applications, :local_planning_authority_id
  end
end
