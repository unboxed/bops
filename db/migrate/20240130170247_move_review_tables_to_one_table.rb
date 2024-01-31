# frozen_string_literal: true

class MoveReviewTablesToOneTable < ActiveRecord::Migration[7.1]
  class Review < ApplicationRecord
    store_accessor :specific_attributes, %w[decision decision_reason summary decision_type removed review_type]
    belongs_to :reviewable, polymorphic: true, optional: true
    belongs_to :owner, polymorphic: true
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

    drop_table :review_local_policies
    drop_table :review_policy_classes
    drop_table :review_immunity_details
  end

  def down
  end
end
