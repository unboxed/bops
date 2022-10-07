# frozen_string_literal: true

class AddStatusToRecommendation < ActiveRecord::Migration[6.1]
  def up
    add_column(:recommendations, :status, :integer, default: 0, null: false)

    execute(
      "UPDATE recommendations
      SET status = 1
      FROM planning_applications
      WHERE planning_applications.id = recommendations.planning_application_id
      AND planning_applications.status IN ('in_assessment', 'awaiting_determination');"
    )

    execute(
      "UPDATE recommendations
      SET status = 3
      WHERE reviewed_at IS NOT NULL;"
    )
  end

  def down
    remove_column(:recommendations, :status)
  end
end
