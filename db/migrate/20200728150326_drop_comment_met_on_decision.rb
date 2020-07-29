class DropCommentMetOnDecision < ActiveRecord::Migration[6.0]
  def change
    remove_column :decisions, :comment_met, :text
  end
end
