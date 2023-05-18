# frozen_string_literal: true

class AddReviewTypeAndRemoveNotNullConstraintsOnReviewImmunityDetails < ActiveRecord::Migration[7.0]
  def change
    add_column :review_immunity_details, :review_type, :string, default: "enforcement"

    change_column_null :review_immunity_details, :decision, true
    change_column_null :review_immunity_details, :decision_reason, true

    up_only do
      ReviewImmunityDetail.find_each do |review_immunity_detail|
        review_immunity_detail.update(review_type: "enforcement")
      end
    end

    change_column_null :review_immunity_details, :review_type, false
  end
end
