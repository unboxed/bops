# frozen_string_literal: true

require "aasm"

class PlanningApplication < ApplicationRecord
  include AASM

  enum application_type: { lawfulness_certificate: 0, full: 1 }

  has_many :documents, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :description_change_requests, dependent: :destroy

  belongs_to :user, optional: true
  belongs_to :local_authority

  before_create :set_target_date
  before_create :set_change_access_id
  before_update :set_target_date

  WORK_STATUSES = %w[proposed existing].freeze

  validates :work_status,
            inclusion: { in: WORK_STATUSES,
                         message: "Work Status should be proposed or existing" }
  validates :application_type, presence: true

  validate :applicant_or_agent_email
  validate :documents_validated_at_date
  validate :public_comment_present
  validate :decision_with_recommendations

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
      transitions from: %i[in_assessment awaiting_correction], to: :awaiting_determination, guard: :decision_present?
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
    awaiting_correction?
  end

  def reviewer_disagrees_with_assessor?
    awaiting_correction?
  end

  def assessor_decision_updated?
    awaiting_determination? && recommendations.count > 1
  end

  def reviewer_decision_updated?
    awaiting_correction? && recommendations.count > 1
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

  def refused?
    decision == "refused"
  end

  def granted?
    decision == "granted"
  end

  def can_validate?
    true unless awaiting_determination? || determined? || returned? || withdrawn?
  end

  def validation_complete?
    !not_started?
  end

  def can_assess?
    in_assessment? || awaiting_correction?
  end

  def assessment_complete?
    (validation_complete? && pending_review?) || awaiting_determination? || determined?
  end

  def can_submit_recommendation?
    assessment_complete? && (in_assessment? || awaiting_correction?)
  end

  def submit_recommendation_complete?
    awaiting_determination? || determined?
  end

  def can_review_assessment?
    awaiting_determination?
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

  def pending_or_new_recommendation
    recommendations.pending_review.last || recommendations.build
  end

  def parsed_proposal_details
    proposal_details.present? ? JSON.parse(proposal_details) : []
  end

  def full_address
    "#{address_1}, #{town}, #{postcode}"
  end

  def secure_change_url(application_id, secure_token)
    if ENV["RAILS_ENV"] == "production" || ENV["RAILS_ENV"] == "preview"
      "https://#{local_authority.subdomain}.#{ENV['APPLICANTS_APP_HOST']}/change_requests?planning_application_id=#{application_id}&change_access_id=#{secure_token}"
    else
      "http://#{local_authority.subdomain}.#{ENV['APPLICANTS_APP_HOST']}/change_requests?planning_application_id=#{application_id}&change_access_id=#{secure_token}"
    end
  end

private

  def set_target_date
    self.target_date = (documents_validated_at || created_at) + 8.weeks
  end

  def set_change_access_id
    self.change_access_id = SecureRandom.hex(15)
  end

  def documents_validated_at_date
    if in_assessment? && !documents_validated_at.is_a?(Date)
      errors.add(:planning_application, "Please enter a valid date")
    end
  end

  def has_validation_date?
    !documents_validated_at.nil?
  end

  def public_comment_present
    if decision_present? && public_comment.blank?
      errors.add(:planning_application, "Please state the reasons why this application is, or is not lawful")
    end
  end

  def decision_present?
    decision.present?
  end

  def decision_with_recommendations
    if decision.nil? && recommendations.any?
      errors.add(:planning_application, "Please select Yes or No")
    end
  end

  def applicant_or_agent_email
    unless applicant_email? || agent_email?
      errors.add(:base, "An applicant or agent email is required.")
    end
  end
end
