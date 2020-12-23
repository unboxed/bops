class AddCancellationCommentToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :cancellation_comment, :text
  end
end
