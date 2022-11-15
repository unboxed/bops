class CreateReviewPolicyClasses < ActiveRecord::Migration[6.1]
  def change
    create_table :review_policy_classes do |t|
      t.integer :mark
      t.belongs_to :policy_class, null: false, foreign_key: true
      t.integer :status

      t.timestamps
    end
  end
end
