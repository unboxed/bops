class RemoveReferenceFromPlanningApplication < ActiveRecord::Migration[6.0]
  def change
    remove_column :planning_applications, :reference, :string
  end
end
