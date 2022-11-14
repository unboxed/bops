# frozen_string_literal: true

class AddReviewStatusToPolicyClasses < ActiveRecord::Migration[6.1]
  def change
    add_column :policy_classes, :review_status, :integer
  end
end
