class AddEnabledToLocalPolicyAreas < ActiveRecord::Migration[7.1]
  def change
    add_column :local_policy_areas, :enabled, :boolean, default: false
  end
end
