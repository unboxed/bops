# frozen_string_literal: true

class AddMissingImmunityDetailForeignKeyToReviewImmunityDetails < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :review_immunity_details, :immunity_details
  end
end
