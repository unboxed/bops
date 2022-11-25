# frozen_string_literal: true

class RenameAssessmentDetailReviewStatus < ActiveRecord::Migration[6.1]
  def change
    rename_column(:assessment_details, :review_status, :reviewer_verdict)
  end
end
