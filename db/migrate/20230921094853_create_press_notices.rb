# frozen_string_literal: true

class CreatePressNotices < ActiveRecord::Migration[7.0]
  def change
    create_table :press_notices do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.boolean :required, null: false
      t.jsonb :reasons
      t.datetime :requested_at
      t.datetime :press_sent_at
      t.datetime :published_at

      t.timestamps
    end
  end
end
