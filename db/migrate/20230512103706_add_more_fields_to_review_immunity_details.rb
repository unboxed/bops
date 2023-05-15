# frozen_string_literal: true

class AddMoreFieldsToReviewImmunityDetails < ActiveRecord::Migration[7.0]
  def change
    change_table :review_immunity_details, bulk: true do |t|
      t.boolean :removed
      t.boolean :reviewer_edited, default: false, null: false
      t.string :review_status, default: "review_not_started", null: false
    end
  end
end
