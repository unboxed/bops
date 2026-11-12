# frozen_string_literal: true

class CreateCaseConstraints < ActiveRecord::Migration[8.1]
  def change
    create_table :case_constraints do |t|
      t.bigint :constrainable_id, null: false
      t.string :constrainable_type, null: false
      t.references :constraint, null: false, foreign_key: true
      t.jsonb :data
      t.boolean :identified, null: false, default: false
      t.string :identified_by, null: false
      t.jsonb :metadata
      t.datetime :removed_at
      t.string :status, null: false, default: "pending"

      t.timestamps
    end
  end
end
