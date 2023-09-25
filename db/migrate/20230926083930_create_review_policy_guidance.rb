# frozen_string_literal: true

class CreateReviewPolicyGuidance < ActiveRecord::Migration[7.0]
  def change
    create_table :review_policy_guidances do |t|
      t.references :policy_guidance
      t.references :assessor, foreign_key: { to_table: :users }
      t.references :reviewer, foreign_key: { to_table: :users }
      t.boolean :accepted, default: false, null: false
      t.string :status, default: "in_progress", null: false
      t.string :review_status, default: "review_not_started", null: false
      t.boolean :reviewer_edited, default: false, null: false
      t.text :reviewer_comment
      t.datetime :reviewed_at
      t.timestamps
    end

    change_table :policy_guidances, bulk: true do |t|
      t.string :review_status, default: "review_not_started", null: false
      t.string :status, default: "not_started", null: false
      t.references :assessor, foreign_key: { to_table: :users }
      t.references :reviewer, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
    end
  end
end
