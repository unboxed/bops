# frozen_string_literal: true

class AddTimeStampToInAssessmentInProgress < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :assessment_in_progress_at, :timestamp
  end
end
