# frozen_string_literal: true

class RemoveUpdatedFromAssessmentDetailReviewerVerdict < ActiveRecord::Migration[6.1]
  def up
    execute(
      "UPDATE assessment_details
      SET reviewer_verdict = NULL
      WHERE reviewer_verdict = 'updated';"
    )
  end

  def down
  end
end
