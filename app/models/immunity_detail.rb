# frozen_string_literal: true

class ImmunityDetail < ApplicationRecord
  belongs_to :planning_application
  has_many :evidence_groups, dependent: :destroy
  has_many :comments, as: :commentable, through: :evidence_groups, dependent: :destroy

  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review"

  accepts_nested_attributes_for :evidence_groups, :comments, :reviews

  before_update :maybe_create_review

  def update_required?
    current_evidence_review_immunity_detail.status == "complete" && !accepted?
  end

  def add_document(document)
    tag = document.tags.intersection(Document::EVIDENCE_TAGS).first.delete(" ").underscore
    evidence_group = evidence_groups.find_or_create_by!(tag:)
    evidence_group.documents << document
    evidence_group.save!
  end

  def accepted?
    current_evidence_review_immunity_detail.status == "complete" &&
      (current_evidence_review_immunity_detail.review_status == "review_complete" || current_evidence_review_immunity_detail.review_status == "review_in_progress")
  end

  def current_enforcement_review_immunity_detail
    reviews.enforcement.where.not(id: nil).order(:created_at).last
  end

  def current_evidence_review_immunity_detail
    reviews.evidence.where.not(id: nil).order(:created_at).last
  end

  def earliest_evidence_cover
    evidence_groups.order(start_date: :asc).first&.start_date
  end

  def latest_evidence_cover
    evidence_groups.pluck(:end_date, :start_date).flatten.compact.max
  end

  def evidence_gaps?
    return if evidence_groups.blank?

    evidence_groups.any?(&:missing_evidence?)
  end

  private

  def maybe_create_review
    return if current_evidence_review_immunity_detail.nil?
    return unless current_evidence_review_immunity_detail.status_changed? && current_evidence_review_immunity_detail_review.status_change == %w[to_be_reviewed complete]

    reviews.create!(owner: self, specific_attributes: {review_type: "evidence"}, assessor: Current.owner)
  end
end
