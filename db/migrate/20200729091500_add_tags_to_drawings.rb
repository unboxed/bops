class AddTagsToDrawings < ActiveRecord::Migration[6.0]
  def change
    add_column :drawings, :tags, :jsonb, default: [], null: false
  end
end
