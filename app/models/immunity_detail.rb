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
    complete? && !accepted
  end

  def add_document(document)
    tag = document.tags.intersection(Document::EVIDENCE_TAGS).first.delete(" ").underscore
    evidence_group = evidence_groups.find_or_create_by(tag:)
    evidence_group.documents << document
    # TODO: update start/end date?
    evidence_group.save!
  end

  def accepted?
    status == "complete" && review_status == "review_complete"
  end
end
