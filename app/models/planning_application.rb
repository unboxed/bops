# frozen_string_literal: true

require "aasm"

class PlanningApplication < ApplicationRecord
  include AASM

  enum application_type: { lawfulness_certificate: 0, full: 1 }

  has_one :policy_evaluation, dependent: :destroy
  has_many :decisions, dependent: :destroy

  has_many :drawings, dependent: :destroy

  has_one :assessor_decision, -> {
      joins(:user).where(users: { role: :assessor })
    }, class_name: "Decision", inverse_of: :planning_application

  has_one :reviewer_decision, -> {
      joins(:user).where(users: { role: :reviewer })
    }, class_name: "Decision", inverse_of: :planning_application

  belongs_to :site
  belongs_to :user, optional: true
  belongs_to :local_authority

  before_create :set_target_date

  validate :assessor_decision_associated_with_assessor
  validate :reviewer_decision_associated_with_reviewer

  STATUSES = %w[in_assessment awaiting_determination awaiting_correction determined]

  validates :status, inclusion: STATUSES

  STATUSES.each do |status_string|
    define_method "#{status_string}?" do
      status == status_string
    end

    define_method "#{status_string}!" do
      update(status: status_string)
    end

    scope status_string.to_sym, -> { where(status: status_string) }
  end

  aasm.attribute_name :status

  aasm do
    state :in_assessment, initial: true
    state :awaiting_determination
    state :awaiting_correction
    state :determined

    event :assess do
      transitions from: :in_assessment, to: :awaiting_determination, guard: :drawings_ready_for_publication?
    end

    event :determine do
      transitions from: :awaiting_determination, to: :determined
    end

    event :request_correction do
      transitions from: :awaiting_determination, to: :awaiting_correction
    end

    event :provide_correction do
      transitions from: :awaiting_correction, to: :awaiting_determination
    end

    after_all_transitions :timestamp_status_change
  end

  def timestamp_status_change
    update("#{aasm.to_state}_at": Time.current)
  end

  def days_left
    (target_date - Date.current).to_i
  end

  def update_and_timestamp_status(status)
    update(status: status, "#{status}_at": Time.current)
  end

  def reference
    @_reference ||= id.to_s.rjust(8, "0")
  end

  def correction_provided?
    awaiting_determination? && reviewer_decision&.private_comment.present?
  end

  def reviewer_disagrees_with_assessor?
    return false unless reviewer_decision && assessor_decision

    reviewer_decision.status != assessor_decision.status
  end

  def assessor_decision_updated?
    return false unless assessor_decision && reviewer_decision

    assessor_decision.decided_at > reviewer_decision.decided_at
  end

  def reviewer_decision_updated?
    return false unless reviewer_decision && assessor_decision

    reviewer_decision.decided_at > assessor_decision.decided_at
  end

  def assessment_complete?
    awaiting_determination? || determined?
  end

  def agent?
    agent_first_name? && agent_last_name? && (agent_phone? || agent_email?)
  end

  def applicant?
    applicant_first_name? && applicant_last_name? && (applicant_phone? || applicant_email?)
  end

  def review_complete?
    awaiting_correction? || determined?
  end

  def drawings_ready_for_publication?
    drawings_for_publication = drawings.for_publication

    drawings_for_publication.present? &&
      drawings_for_publication.has_empty_numbers.none?
  end

  def drawing_numbering_partially_completed?
    numbered_count = drawings.has_proposed_tag.numbered.count

    return false if numbered_count.zero?

    numbered_count < drawings.has_proposed_tag.count
  end

  private

  def set_target_date
    self.target_date = created_at + 8.weeks
  end

  def assessor_decision_associated_with_assessor
    if assessor_decision.present? && !assessor_decision.user.assessor?
      errors.add(:assessor_decision, "cannot be associated with a non-assessor")
    end
  end

  def reviewer_decision_associated_with_reviewer
    if reviewer_decision.present? && !reviewer_decision.user.reviewer?
      errors.add(:reviewer_decision, "cannot be associated with a non-reviewer")
    end
  end
end
