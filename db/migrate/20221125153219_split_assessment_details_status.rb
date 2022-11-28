# frozen_string_literal: true

class SplitAssessmentDetailsStatus < ActiveRecord::Migration[6.1]
  # rubocop:disable Metrics/MethodLength
  def up
    rename_column(:assessment_details, :status, :assessment_status)
    add_column(:assessment_details, :review_status, :string)

    execute(
      "UPDATE assessment_details
      SET review_status = 'in_progress'
      WHERE assessment_status = 'review_in_progress';"
    )

    execute(
      "UPDATE assessment_details
      SET review_status = 'complete'
      WHERE assessment_status = 'review_complete';"
    )

    execute(
      "UPDATE assessment_details
      SET assessment_status = 'in_progress'
      WHERE assessment_status = 'assessment_in_progress';"
    )

    execute(
      "UPDATE assessment_details
      SET assessment_status = 'complete'
      WHERE assessment_status
      IN ('assessment_in_progress', 'review_in_progress', 'review_complete');"
    )
  end

  def down
    execute(
      "UPDATE assessment_details
      SET assessment_status = 'assessment_in_progress'
      WHERE assessment_status = 'in_progress';"
    )

    execute(
      "UPDATE assessment_details
      SET assessment_status = 'assessment_complete'
      WHERE assessment_status = 'complete';"
    )

    execute(
      "UPDATE assessment_details
      SET assessment_status = 'review_in_progress'
      WHERE review_status = 'in_progress';"
    )

    execute(
      "UPDATE assessment_details
      SET assessment_status = 'review_complete'
      WHERE review_status = 'complete';"
    )

    rename_column(:assessment_details, :assessment_status, :status)
    remove_column(:assessment_details, :review_status, :string)
  end
  # rubocop:enable Metrics/MethodLength
end
