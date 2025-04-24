# frozen_string_literal: true

class ValidateSubmissionForeignKeyOnPlanningApplications < ActiveRecord::Migration[7.2]
  def change
    validate_foreign_key :planning_applications, :submissions
  end
end
