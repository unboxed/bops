class AddArchivedAtToDrawings < ActiveRecord::Migration[6.0]
  def change
    add_column :drawings, :archived_at, :datetime
  end
end
