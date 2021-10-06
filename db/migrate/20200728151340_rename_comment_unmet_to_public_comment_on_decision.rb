# frozen_string_literal: true

class RenameCommentUnmetToPublicCommentOnDecision < ActiveRecord::Migration[6.0]
  def change
    rename_column :decisions, :comment_unmet, :public_comment
  end
end
