class RemoveSiteFromPlanningApplication < ActiveRecord::Migration[6.0]
  def change
    remove_column :planning_applications, :site_id
  end
end
