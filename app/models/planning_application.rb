# frozen_string_literal: true

require "aasm"

class PlanningApplication < ApplicationRecord
  include AASM

  enum application_type: { lawfulness_certificate: 0, full: 1 }

  has_one :policy_evaluation, dependent: :destroy
  has_many :decisions, dependent: :destroy

  has_many :documents, dependent: :destroy

  has_one :assessor_decision, lambda {
                                joins(:user).where(users: { role: :assessor })
                              }, class_name: "Decision", inverse_of: :planning_application

  has_one :reviewer_decision, lambda {
                                joins(:user).where(users: { role: :reviewer })
                              }, class_name: "Decision", inverse_of: :planning_application

  belongs_to :site
  belongs_to :user, optional: true
  belongs_to :local_authority

  before_create :set_target_date
  before_update :set_target_date

  validate :assessor_decision_associated_with_assessor
  validate :reviewer_decision_associated_with_reviewer

  WORK_STATUSES = %w[proposed existing].freeze

  validates :work_status,
            inclusion: { in: WORK_STATUSES,
                         message: "Work Status should be proposed or existing" }

  validate :documents_validated_at_date

  scope :not_started_and_invalid, -> { where("status = 'not_started' OR status = 'invalidated'") }
  scope :under_assessment, -> { where("status = 'in_assessment' OR status = 'awaiting_correction'") }
  scope :closed, -> { where("status = 'determined' OR status = 'withdrawn' OR status = 'returned'") }

  aasm.attribute_name :status

  aasm do
    state :not_started, initial: true
    state :invalidated
    state :in_assessment
    state :awaiting_determination
    state :awaiting_correction
    state :determined
    state :returned
    state :withdrawn

    event :start do
      transitions from: %i[not_started invalidated in_assessment], to: :in_assessment, guard: :has_validation_date?
    end

    event :assess do
      transitions from: %i[in_assessment awaiting_correction], to: :awaiting_determination
    end

    event :invalidate do
      transitions from: %i[not_started invalidated in_assessment awaiting_determination awaiting_correction], to: :invalidated
    end

    event :determine do
      transitions from: :awaiting_determination, to: :determined
    end

    event :request_correction do
      transitions from: :awaiting_determination, to: :awaiting_correction
    end

    event :return do
      transitions from: %i[not_started
                           in_assessment
                           invalidated
                           awaiting_determination
                           awaiting_correction
                           returned], to: :returned, after: proc { |comment|
                                                              update!(cancellation_comment: comment)
                                                            }
    end

    event :withdraw do
      transitions from: %i[not_started
                           in_assessment
                           invalidated
                           awaiting_determination
                           awaiting_correction
                           returned], to: :withdrawn, after: proc { |comment|
                                                               update!(cancellation_comment: comment)
                                                             }
    end

    after_all_transitions :timestamp_status_change
  end

  def applicant_name
    "#{applicant_first_name} #{applicant_last_name}"
  end

  def timestamp_status_change
    update("#{aasm.to_state}_at": Time.zone.now)
  end

  def days_left
    (target_date - Date.current).to_i
  end

  def reference
    @reference ||= id.to_s.rjust(8, "0")
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

  def recommendable?
    true unless determined? || returned? || withdrawn? || invalidated? || not_started?
  end

  def in_progress?
    true unless determined? || returned? || withdrawn?
  end

private

  def set_target_date
    self.target_date = (documents_validated_at || created_at) + 8.weeks
  end

  def documents_validated_at_date
    if in_assessment? && !documents_validated_at.is_a?(Date)
      errors.add(:planning_application, "Please enter a valid date")
    end
  end

  def has_validation_date?
    !documents_validated_at.nil?
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
