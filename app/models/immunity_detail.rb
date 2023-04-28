# frozen_string_literal: true

class ImmunityDetail < ApplicationRecord
  belongs_to :planning_application
  has_many :evidence_groups, dependent: :destroy
  has_many :comments, as: :commentable, through: :evidence_groups, dependent: :destroy

  has_many :review_immunity_details, dependent: :destroy

  accepts_nested_attributes_for :evidence_groups
  accepts_nested_attributes_for :comments

  enum(
    status: {
      not_started: "not_started",
      in_progress: "in_progress",
      to_be_reviewed: "to_be_reviewed",
      complete: "complete"
    },
    _default: "not_started"
  )

  enum review_status: {
    review_not_started: "review_not_started",
    review_in_progress: "review_in_progress",
    review_complete: "review_complete"
  }

  with_options presence: true do
    validates :status, :review_status
  end

  def update_required?
    complete? && !accepted?
  end

  def add_document(document)
    tag = document.tags.intersection(Document::EVIDENCE_TAGS).first.delete(" ").underscore
    evidence_group = evidence_groups.find_or_create_by(tag:)
    evidence_group.documents << document
    evidence_group.save!
  end

  def accepted?
    status == "complete" && (review_status == "review_complete" || review_status == "review_in_progress")
  end

  def current_review_immunity_detail
    review_immunity_details.where.not(id: nil).last
  end

  def earliest_evidence_cover
    evidence_groups.order(start_date: :asc).first&.start_date
  end

  def latest_evidence_cover
    group = evidence_groups.order(end_date: :asc, start_date: :asc).last
    group&.end_date || group&.start_date
  end

  def evidence_gaps?
    return if evidence_groups.blank?

    evidence_groups.any?(&:missing_evidence?)
  end
end
