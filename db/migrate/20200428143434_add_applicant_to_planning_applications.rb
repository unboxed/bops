class AddApplicantToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_reference :planning_applications, :applicant, null: true
  end
end
