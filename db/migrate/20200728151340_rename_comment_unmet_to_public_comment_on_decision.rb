class RenameCommentUnmetToPublicCommentOnDecision < ActiveRecord::Migration[6.0]
  def change
    rename_column :decisions, :comment_unmet, :private_comment
  end
end
