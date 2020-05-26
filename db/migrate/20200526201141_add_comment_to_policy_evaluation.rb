class AddCommentToPolicyEvaluation < ActiveRecord::Migration[6.0]
  def change
    add_column :policy_evaluations, :comment_met, :text
    add_column :policy_evaluations, :comment_unmet, :text
  end
end
