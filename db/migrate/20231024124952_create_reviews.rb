# frozen_string_literal: true

class CreateReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :reviews do |t|
      t.string :action
      t.references :assessor, foreign_key: {to_table: :users}, index: true
      t.references :reviewable, null: false, polymorphic: true, index: true
      t.datetime :reviewed_at
      t.references :reviewer, foreign_key: {to_table: :users}, index: true
      t.text :comment
      t.string :status, default: "not_started", null: false
      t.timestamps
    end
  end
end
