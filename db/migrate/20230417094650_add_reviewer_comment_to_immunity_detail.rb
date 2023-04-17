# frozen_string_literal: true

class AddReviewerCommentToImmunityDetail < ActiveRecord::Migration[7.0]
  def change
    remove_column :immunity_details, :reviewer_id
    remove_column :immunity_details, :assessor_id
    remove_column :immunity_details, :reviewed_at

    create_table :review_immunity_details do |t|
      t.references :immunity_details
      t.text :assessor_comment
      t.references :assessor, foreign_key: { to_table: :users }
      t.text :reviewer_comment
      t.references :reviewer, foreign_key: { to_table: :users }
      t.string :assessor_decision
      t.string :reviewer_decision
      t.datetime :assessor_decision_updated_at
      t.datetime :reviewer_decision_updated_at
      t.timestamps
    end
  end
end
