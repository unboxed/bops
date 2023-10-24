# frozen_string_literal: true

class CreateReviewPolicyClasses < ActiveRecord::Migration[6.1]
  def change
    create_table :review_policy_classes do |t|
      t.belongs_to :policy_class, null: false, foreign_key: true
      t.integer :mark, null: false
      t.string :comment
      t.integer :status, null: false
      t.timestamps
    end
  end
end
