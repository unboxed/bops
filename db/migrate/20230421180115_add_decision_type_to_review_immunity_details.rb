# frozen_string_literal: true

class AddDecisionTypeToReviewImmunityDetails < ActiveRecord::Migration[7.0]
  def change
    add_column :review_immunity_details, :decision_type, :string

    change_column_null :review_immunity_details, :decision, false
    change_column_null :review_immunity_details, :decision_reason, false
  end
end
