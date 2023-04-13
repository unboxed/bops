class AddReviewStatusToImmunityDetail < ActiveRecord::Migration[7.0]
  def change
    add_column :immunity_details, :review_status, :string, default: "review_not_started", null: false
  end
end
