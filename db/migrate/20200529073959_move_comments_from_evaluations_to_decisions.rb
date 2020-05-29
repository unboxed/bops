class MoveCommentsFromEvaluationsToDecisions < ActiveRecord::Migration[6.0]
  def change
    remove_column :policy_evaluations, :comment_met, :text
    remove_column :policy_evaluations, :comment_unmet, :text

    add_column :decisions, :comment_met, :text
    add_column :decisions, :comment_unmet, :text
  end
end
