class AddInAssessmentAtToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :in_assessment_at, :datetime, null: true
  end
end
