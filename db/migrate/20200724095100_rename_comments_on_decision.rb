class RenameCommentsOnDecision < ActiveRecord::Migration[6.0]
  def change
    remove_column :decisions, :comment_met, :text
    remove_column :decisions, :comment_unmet, :text
    add_column :decisions, :comment, :text
  end
end
