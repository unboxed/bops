# frozen_string_literal: true

class AddStatusToReviewImmunityDetails < ActiveRecord::Migration[7.0]
  def change
    add_column :review_immunity_details, :status, :string, default: "in_progress", null: false
  end
end
