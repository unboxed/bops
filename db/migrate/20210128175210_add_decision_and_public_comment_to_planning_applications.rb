class AddDecisionAndPublicCommentToPlanningApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :planning_applications, :decision, :string
    add_column :planning_applications, :public_comment, :text
  end
end
