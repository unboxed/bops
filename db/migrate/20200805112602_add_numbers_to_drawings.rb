class AddNumbersToDrawings < ActiveRecord::Migration[6.0]
  def change
    add_column :drawings, :numbers, :jsonb, default: [], null: false
  end
end
