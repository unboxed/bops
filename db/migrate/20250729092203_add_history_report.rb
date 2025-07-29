# frozen_string_literal: true

class AddHistoryReport < ActiveRecord::Migration[7.2]
  def change
    create_table :history_reports do |t|
      t.jsonb :raw, null: false
      t.boolean :checked, default: false, null: false
      t.string :error_message
      t.string :uprn
      t.datetime :refreshed_at
      t.references :planning_application, null: false, foreign_key: true

      t.timestamps
    end
  end
end
