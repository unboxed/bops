# frozen_string_literal: true

class AddReviewImmunityDetails < ActiveRecord::Migration[7.0]
  def up
    create_table :review_immunity_details do |t|
      t.references :immunity_details
      t.references :assessor, foreign_key: { to_table: :users }
      t.references :reviewer, foreign_key: { to_table: :users }
      t.string :decision
      t.text :decision_reason
      t.text :summary
      t.boolean :accepted, default: false, null: false
      t.text :reviewer_comment
      t.datetime :reviewed_at

      t.timestamps
    end

    remove_reference :immunity_details, :reviewer
    remove_reference :immunity_details, :assessor
    remove_column :immunity_details, :reviewed_at, :datetime
  end

  def down
    drop_table :review_immunity_details if table_exists?(:review_immunity_details)

    change_table :immunity_details, bulk: true do |t|
      t.references :assessor, foreign_key: { to_table: :users }
      t.references :reviewer, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
    end
  end
end
