class AddPrivateCommentOnDecision < ActiveRecord::Migration[6.0]
  def change
    add_column :decisions, :private_comment, :text
  end
end
