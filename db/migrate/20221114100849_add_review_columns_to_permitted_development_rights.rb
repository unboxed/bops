# frozen_string_literal: true

class AddReviewColumnsToPermittedDevelopmentRights < ActiveRecord::Migration[6.1]
  def change
    change_table :permitted_development_rights, bulk: true do |t|
      t.string :review_status, default: "review_not_started", null: false
      t.text :reviewer_comment
      t.boolean :reviewer_edited, default: false, null: false
      t.boolean :accepted, default: false, null: false
      t.datetime :reviewed_at
      t.references :assessor, foreign_key: {to_table: :users}
      t.references :reviewer, foreign_key: {to_table: :users}
    end

    up_only do
      PermittedDevelopmentRight.find_each do |permitted_development_right|
        permitted_development_right.update(review_status: "review_not_started", reviewer_edited: false, accepted: false)
      end
    end
  end
end
