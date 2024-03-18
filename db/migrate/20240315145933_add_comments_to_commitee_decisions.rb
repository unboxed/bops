class AddCommentsToCommiteeDecisions < ActiveRecord::Migration[7.1]
  def change
    add_column :committee_decisions, :comments, :text
  end
end
