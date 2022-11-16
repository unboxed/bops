# frozen_string_literal: true

class AddReviewStatusToAssessmentSummaries < ActiveRecord::Migration[6.1]
  def change
    add_column :assessment_details, :review_status, :string
  end
end
