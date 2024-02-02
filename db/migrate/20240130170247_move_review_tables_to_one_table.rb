# frozen_string_literal: true

class MoveReviewTablesToOneTable < ActiveRecord::Migration[7.1]
  class Review < ApplicationRecord
    store_accessor :specific_attributes, %w[decision decision_reason summary decision_type removed review_type]
    belongs_to :reviewable, polymorphic: true, optional: true
    belongs_to :owner, polymorphic: true

    with_options class_name: "User", optional: true do
      belongs_to :assessor
      belongs_to :reviewer
    end
  end

  class ReviewLocalPolicy < ApplicationRecord
    with_options class_name: "User", optional: true do
      belongs_to :assessor
      belongs_to :reviewer
    end
  end

  class ReviewPolicyClass < ApplicationRecord
    belongs_to :policy_class, optional: true
  end

  class ReviewImmunityDetail < ApplicationRecord
    with_options class_name: "User", optional: true do
      belongs_to :assessor
      belongs_to :reviewer
    end
  end

  def up
    change_table :reviews, bulk: true do |t|
      t.string :review_status, default: "review_not_started", null: false
      t.boolean :reviewer_edited, null: false, default: false
      t.jsonb :specific_attributes
      t.rename :reviewable_type, :owner_type
      t.rename :reviewable_id, :owner_id
    end

    Review.find_each do |review|
      review.assign_attributes(
        review_status: review.owner.status
      )
      review.save!(validate: false)
    end

    ReviewPolicyClass.find_each do |review|
      r = Review.create!(
        owner_type: "PolicyClass",
        owner_id: review.policy_class_id,
        action: review.mark,
        review_status: review.status,
        status: review.policy_class.status,
        comment: review.comment
      )
      r.update!(created_at: review.created_at, updated_at: review.updated_at)
    end

    ReviewLocalPolicy.find_each do |review|
      r = Review.create!(
        owner_type: "LocalPolicy",
        owner_id: review.local_policy_id,
        action: review.accepted? ? "accepted" : "rejected",
        assessor_id: review.assessor_id,
        reviewer_id: review.reviewer_id,
        status: review.status,
        review_status: review.review_status,
        reviewer_edited: review.reviewer_edited,
        comment: review.reviewer_comment,
        reviewed_at: review.reviewed_at
      )
      r.update!(created_at: review.created_at, updated_at: review.updated_at)
    end

    ReviewImmunityDetail.find_each do |review|
      r = Review.create!(
        owner_type: "ImmunityDetail",
        owner_id: review.immunity_detail_id,
        action: review.accepted? ? "accepted" : "rejected",
        assessor_id: review.assessor_id,
        reviewer_id: review.reviewer_id,
        status: review.status,
        review_status: review.review_status,
        reviewer_edited: review.reviewer_edited,
        comment: review.reviewer_comment,
        reviewed_at: review.reviewed_at,
        decision: review.decision,
        decision_reason: review.decision_reason,
        summary: review.summary,
        decision_type: review.decision_type,
        removed: review.removed,
        review_type: review.review_type
      )
      r.update!(created_at: review.created_at, updated_at: review.updated_at)
    end

    change_table :local_policies, bulk: true do |t|
      t.remove :status
      t.remove :review_status
      t.remove :assessor_id
      t.remove :reviewer_id
      t.remove :reviewed_at
    end

    change_table :immunity_details, bulk: true do |t|
      t.remove :status
      t.remove :review_status
    end

    remove_column :policy_classes, :status

    drop_table :review_local_policies
    drop_table :review_policy_classes
    drop_table :review_immunity_details
  end

  def down
    create_table "review_policy_classes", force: :cascade do |t|
      t.references :policy_class, null: false
      t.integer :mark, null: false
      t.string :comment
      t.integer :status, null: false
      t.timestamps
    end

    create_table "review_local_policies", force: :cascade do |t|
      t.references :assessor, null: false, foreign_key: {to_table: :users}
      t.references :reviewer, foreign_key: {to_table: :users}
      t.boolean :accepted, default: false, null: false
      t.string :status, default: "in_progress", null: false
      t.string :review_status, default: "review_not_started", null: false
      t.boolean :reviewer_edited, default: false, null: false
      t.text :reviewer_comment
      t.datetime :reviewed_at
      t.references :local_policy
      t.timestamps
    end

    create_table "review_immunity_details", force: :cascade do |t|
      t.references :immunity_detail
      t.references :assessor, null: false, foreign_key: {to_table: :users}
      t.references :reviewer, foreign_key: {to_table: :users}
      t.string :decision
      t.text :decision_reason
      t.text :summary
      t.boolean :accepted, default: false, null: false
      t.text :reviewer_comment
      t.datetime :reviewed_at
      t.string :decision_type
      t.string :status, default: "in_progress", null: false
      t.boolean :removed, null: false, default: false
      t.boolean :reviewer_edited, default: false, null: false
      t.string :review_status, default: "review_not_started", null: false
      t.string :review_type, default: "enforcement", null: false
      t.timestamps
    end

    Review.find_each do |review|
      case review.owner_type
      when "LocalPolicy"
        rlp = ReviewLocalPolicy.create!(
          assessor_id: review.assessor.id,
          reviewer_id: review.reviewer&.id,
          accepted: if review.action.nil?
                      nil
                    else
                      review.action == "accepted"
                    end,
          status: review.status,
          review_status: review.review_status,
          reviewer_edited: review.reviewer_edited,
          reviewer_comment: review.comment,
          reviewed_at: review.reviewed_at,
          local_policy_id: review.owner.id
        )
        rlp.update!(created_at: review.created_at, updated_at: review.updated_at)
      when "ImmunityDetail"
        rid = ReviewImmunityDetail.create!(
          immunity_detail_id: review.owner.id,
          assessor_id: review.assessor.id,
          reviewer_id: review.reviewer&.id,
          decision: review.specific_attributes["decision"],
          decision_reason: review.specific_attributes["decision_reason"],
          decision_type: review.specific_attributes["decision_type"],
          summary: review.specific_attributes["summary"],
          review_type: review.specific_attributes["review_type"],
          removed: review.specific_attributes["removed"],
          accepted: if review.action.nil?
                      nil
                    else
                      review.action == "accepted"
                    end,
          reviewer_comment: review.comment,
          reviewed_at: review.reviewed_at,
          status: review.status,
          review_status: review.review_status,
          reviewer_edited: review.reviewer_edited
        )
        rid.update!(created_at: review.created_at, updated_at: review.updated_at)
      when "PolicyClass"
        rpc = ReviewPolicyClass.create!(
          policy_class_id: review.owner.id,
          mark: review.action,
          comment: review.comment,
          status: review.status
        )
        rpc.update!(created_at: review.created_at, updated_at: review.updated_at)
      end
    end

    change_table :reviews, bulk: true do |t|
      t.remove :review_status
      t.remove :reviewer_edited
      t.remove :specific_attributes
      t.rename :owner_type, :reviewable_type
      t.rename :owner_id, :reviewable_id
    end
  end
end
