# frozen_string_literal: true

class AddReviewStatusToImmunityDetail < ActiveRecord::Migration[7.0]
  def change
    change_table :immunity_details, bulk: true do |t|
      t.string :review_status, default: "review_not_started", null: false
      t.references :assessor, foreign_key: { to_table: :users }
      t.references :reviewer, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
    end
  end
end
