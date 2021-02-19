class RenameQuestions < ActiveRecord::Migration[6.0]
  def change
    rename_column :planning_applications, :questions, :proposal_details
  end
end
