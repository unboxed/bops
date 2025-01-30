# frozen_string_literal: true

class CreateMeetings < ActiveRecord::Migration[7.2]
  def change
    create_table :meetings do |t|
      t.references :created_by, null: false, foreign_key: {to_table: :users}, type: :bigint
      t.references :planning_application, foreign_key: true
      t.string :status, default: "not_started", null: false
      t.text :comment
      t.datetime :occurred_at, null: false

      t.timestamps
    end
  end
end
