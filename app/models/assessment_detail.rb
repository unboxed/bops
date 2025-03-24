# frozen_string_literal: true

class AssessmentDetail < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user
  has_one :comment, as: :commentable, dependent: :destroy

  enum :assessment_status, %i[not_started in_progress complete].index_with(&:to_s), default: "not_started", prefix: "assessment"

  CATEGORIES_ORDER = %w[
    summary_of_work
    site_description
    additional_evidence
    consultation_summary
    neighbour_summary
    amenity
    summary_of_advice
    check_publicity
  ].freeze

  enum :review_status, %i[
    in_progress
    complete
  ].index_with(&:to_s), prefix: "review"

  enum :reviewer_verdict, %i[
    accepted
    edited_and_accepted
    rejected
  ].index_with(&:to_s)

  enum :category, %i[
    summary_of_work
    site_description
    consultation_summary
    additional_evidence
    neighbour_summary
    amenity
    summary_of_advice
    check_publicity
  ].index_with(&:to_s)

  CATEGORIES = defined_enums["category"].keys.map(&:to_sym).freeze

  enum :summary_tag, %i[complies needs_changes does_not_comply].index_with(&:to_s)

  before_validation :set_user

  validates :assessment_status, presence: true
  validates :entry, presence: true, if: :validate_entry_presence?
  validates :summary_tag, presence: true, if: :summary_of_advice?
  validate :tagged_entry, if: :neighbour_summary?
  validates :reviewer_verdict, presence: true, if: :review_complete?

  scope :by_created_at_desc, -> { order(created_at: :desc) }
  scope :current, -> { by_created_at_desc.group_by(&:category).values.map(&:first) }

  delegate :consultees, to: :planning_application

  accepts_nested_attributes_for :comment

  categories.each do |category|
    scope :"#{category}", -> { where(category:) }
  end

  class << self
    def sorted_by_category(assessment_details)
      assessment_details.sort_by { |ad| CATEGORIES_ORDER.index(ad.category) }
    end
  end

  def existing_or_new_comment
    comment || build_comment
  end

  def update_required?
    review_complete? && rejected?
  end

  def review_required?
    assessment_complete? && reviewer_verdict.blank?
  end

  def to_be_reviewed?
    update_required?
  end

  private

  def validate_entry_presence?
    return false if accepted? || rejected?

    summary_of_work? ||
      site_description? || amenity? || summary_of_advice? || any_neighbour_responses? ||
      (assessment_complete? && consultation_summary?)
  end

  def set_user
    self.user = user || Current.user
  end

  def tagged_entry
    return unless assessment_status == "complete"

    tag_array = NeighbourResponse::TAGS.dup

    entries = tag_array.push(:untagged).map { |tag| entry[/(?<=#{tag.to_s.humanize}:)\s\n/] }

    errors.add(:entry, "Fill in all summaries of comments") if entries.any?
  end

  def any_neighbour_responses?
    return unless planning_application&.consultation
    return unless neighbour_summary?

    planning_application.consultation.neighbour_responses.any?
  end
end
