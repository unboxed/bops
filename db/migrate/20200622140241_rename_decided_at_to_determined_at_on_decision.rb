class RenameDecidedAtToDeterminedAtOnDecision < ActiveRecord::Migration[6.0]
  def change
    rename_column :decisions, :decided_at, :determined_at
  end
end
