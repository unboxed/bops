# frozen_string_literal: true

class CreateConsideration < ActiveRecord::Migration[7.1]
  def change
    create_table :considerations do |t|
      t.references :consideration_set, foreign_key: true
      t.string :policy_area, null: false
      t.jsonb :policy_references, null: false, default: []
      t.jsonb :policy_guidance, null: false, default: []
      t.text :assessment, null: false
      t.text :conclusion, null: false
      t.integer :position
      t.references :submitted_by, index: true, foreign_key: {to_table: :users}
      t.timestamps
    end

    add_index :considerations, [:consideration_set_id, :policy_area], unique: true
  end
end
