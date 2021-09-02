class AddPoliciesToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    change_table :planning_applications do |t|
      t.jsonb :policy_classes, array: true, default: []
    end
  end
end
