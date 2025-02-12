# frozen_string_literal: true

module PlanningApplicationPolicies
  extend ActiveSupport::Concern

  def reviewer_disagrees_with_assessor?
    to_be_reviewed?
  end

  def assessor_decision_updated?
    awaiting_determination? && recommendations.count > 1
  end

  def reviewer_decision_updated?
    to_be_reviewed? && recommendations.count > 1
  end

  def agent?
    agent_first_name? || agent_last_name? || agent_phone? || agent_email?
  end

  def applicant?
    applicant_first_name? || applicant_last_name? || applicant_phone? || applicant_email?
  end

  def review_complete?
    to_be_reviewed? || determined?
  end

  def recommendable?
    true unless closed_or_cancelled? || invalidated? || not_started?
  end

  def in_progress?
    true unless closed_or_cancelled?
  end

  def validated?
    true unless not_started? || invalidated?
  end

  def can_validate?
    true unless awaiting_determination? || closed_or_cancelled?
  end

  def validation_complete?
    !not_started?
  end

  def can_assess?
    assessment_in_progress? || in_assessment? || to_be_reviewed?
  end

  def closed_or_cancelled?
    determined? || returned? || withdrawn? || closed?
  end

  def assessment_complete?
    (validation_complete? && pending_review? && !assessment_in_progress?) || awaiting_determination? || determined?
  end

  def can_submit_recommendation?
    assessment_complete? && (in_assessment? || to_be_reviewed?)
  end

  def submit_recommendation_complete?
    awaiting_determination? || determined?
  end

  def can_review_assessment?
    (awaiting_determination? || in_committee?) && Current.user.reviewer?
  end

  def review_assessment_complete?
    (awaiting_determination? && !pending_review?) || determined?
  end

  def can_publish?
    awaiting_determination? && !pending_review?
  end

  def publish_complete?
    determined?
  end

  def refused_with_public_comment?
    refused? && public_comment.present?
  end

  def pending_review?
    recommendations.pending_review.any?
  end

  def pending_recommendation?
    may_assess? && !pending_review?
  end

  def officer_can_draw_boundary?
    not_started? || invalidated?
  end

  def pending_or_new_recommendation
    recommendations.pending_review.last || recommendations.build
  end

  def existing_or_new_recommendation
    recommendation || recommendations.build
  end

  def consultees_checked?
    consultation&.consultees_checked?
  end

  def can_edit_documents?
    can_validate? || publish_complete?
  end
end
