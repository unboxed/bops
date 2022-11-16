# frozen_string_literal: true

class UpdateAssessmentDetailStatuses < ActiveRecord::Migration[6.1]
  def up
    execute(
      "UPDATE assessment_details
      SET status = 'assessment_in_progress'
      WHERE status = 'in_progress';"
    )

    execute(
      "UPDATE assessment_details
      SET status = 'assessment_complete'
      WHERE status = 'completed';"
    )
  end

  def down
    execute(
      "UPDATE assessment_details
      SET status = in_progress
      WHERE status = 'assessment_in_progress';"
    )

    execute(
      "UPDATE assessment_details
      SET status = 'completed'
      WHERE status = 'assessment_complete';"
    )
  end
end
