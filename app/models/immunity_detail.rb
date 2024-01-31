# frozen_string_literal: true

class ImmunityDetail < ApplicationRecord
  belongs_to :planning_application
  has_many :evidence_groups, dependent: :destroy
  has_many :comments, as: :commentable, through: :evidence_groups, dependent: :destroy

  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review"

  accepts_nested_attributes_for :evidence_groups
  accepts_nested_attributes_for :comments

  after_update :create_evidence_review_immunity_detail

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
    evidence_group = evidence_groups.find_or_create_by!(tag:)
    evidence_group.documents << document
    evidence_group.save!
  end

  def accepted?
    status == "complete" && (review_status == "review_complete" || review_status == "review_in_progress")
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

  def create_evidence_review_immunity_detail
    return if current_evidence_review_immunity_detail.try(:review_not_started?)

    reviews.create!(specific_attributes: { review_type: "evidence" }.to_json, assessor: Current.user, owner: "ImmunityDetail", owner_id: self.id)
  end
end
