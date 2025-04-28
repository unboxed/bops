# frozen_string_literal: true

class CreateSubmissions < ActiveRecord::Migration[7.2]
  def change
    create_table :submissions do |t|
      t.string :status, null: false, default: "submitted"
      t.datetime :started_at
      t.datetime :failed_at
      t.datetime :completed_at
      t.jsonb :request_headers, null: false, default: {}
      t.jsonb :request_body, null: false, default: {}
      t.references :local_authority, null: false, foreign_key: true

      t.timestamps
    end

    add_index :submissions, :status
  end
end
