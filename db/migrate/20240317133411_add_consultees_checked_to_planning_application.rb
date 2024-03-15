class AddConsulteesCheckedToPlanningApplication < ActiveRecord::Migration[7.1]
  def change
    add_column :planning_applications, :consultees_checked, :boolean
  end
end
