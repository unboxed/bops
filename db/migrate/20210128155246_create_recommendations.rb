# frozen_string_literal: true

class CreateRecommendations < ActiveRecord::Migration[6.0]
  def change
    create_table :recommendations do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :assessor, null: false, foreign_key: { to_table: :users }
      t.references :reviewer, foreign_key: { to_table: :users }
      t.text :assessor_comment
      t.text :reviewer_comment
      t.datetime :reviewed_at

      t.timestamps
    end
  end
end
