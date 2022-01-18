# frozen_string_literal: true

class RenameCancellationCommentToClosedOrCancellationCommentOnPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    rename_column :planning_applications, :cancellation_comment, :closed_or_cancellation_comment
  end
end
