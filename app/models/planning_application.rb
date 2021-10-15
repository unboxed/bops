# frozen_string_literal: true

require "aasm"

class PlanningApplication < ApplicationRecord
  include AASM

  enum application_type: { lawfulness_certificate: 0, full: 1 }

  has_many :documents, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :description_change_validation_requests, dependent: :destroy
  has_many :replacement_document_validation_requests, dependent: :destroy
  has_many :other_change_validation_requests, dependent: :destroy
  has_many :additional_document_validation_requests, dependent: :destroy
  has_many :red_line_boundary_change_validation_requests, dependent: :destroy

  belongs_to :user, optional: true
  belongs_to :api_user, optional: true
  belongs_to :boundary_created_by, class_name: "User", optional: true
  belongs_to :local_authority

  before_create :set_key_dates
  before_create :set_change_access_id
  before_update :set_key_dates

  WORK_STATUSES = %w[proposed existing].freeze

  validates :work_status,
            inclusion: { in: WORK_STATUSES,
                         message: "Work Status should be proposed or existing" }
  validates :application_type, presence: true

  validate :applicant_or_agent_email
  validate :documents_validated_at_date
  validate :public_comment_present
  validate :decision_with_recommendations
  validate :policy_classes_editable
  validate :allows_only_one_open_description_change

  scope :not_started_and_invalid, -> { where("status = 'not_started' OR status = 'invalidated'") }
  scope :under_assessment, -> { where("status = 'in_assessment' OR status = 'awaiting_correction'") }
  scope :closed, -> { where("status = 'determined' OR status = 'withdrawn' OR status = 'returned'") }

  attribute :policy_classes, :policy_class, array: true

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
      transitions from: :not_started, to: :invalidated, guard: :pending_validation_requests? do
        after { pending_validation_requests.each(&:mark_as_sent!) }
      end
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
    days_left = Date.current.business_days_until(expiry_date)

    days_left.positive? ? days_left : -expiry_date.business_days_until(Date.current)
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
    agent_first_name? || agent_last_name? || agent_phone? || agent_email?
  end

  def applicant?
    applicant_first_name? || applicant_last_name? || applicant_phone? || applicant_email?
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

  def validated?
    true unless not_started? || invalidated?
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

  def closed?
    determined? || returned? || withdrawn?
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

  def officer_can_draw_boundary?
    not_started? || invalidated?
  end

  def pending_or_new_recommendation
    recommendations.pending_review.last || recommendations.build
  end

  def parsed_proposal_details
    proposal_details.present? ? JSON.parse(proposal_details) : []
  end

  def proposal_details_with_metadata
    parsed_proposal_details.select do |proposal|
      proposal["responses"].any? { |element| element["metadata"].present? }
    end
  end

  def proposal_details_with_flags
    proposal_details_with_metadata.select do |proposal|
      proposal["responses"].any? { |element| element["metadata"]["flags"].present? }
    end
  end

  def flagged_proposal_details(flag)
    proposal_details_with_flags.select do |proposal|
      proposal["responses"].any? { |element| element["metadata"]["flags"].include?(flag) }
    end
  end

  def full_address
    "#{address_1}, #{town}, #{postcode}"
  end

  def secure_change_url
    if Rails.env.production?
      "https://#{local_authority.subdomain}.#{ENV['APPLICANTS_APP_HOST']}/validation_requests?planning_application_id=#{id}&change_access_id=#{change_access_id}"
    else
      "http://#{local_authority.subdomain}.#{ENV['APPLICANTS_APP_HOST']}/validation_requests?planning_application_id=#{id}&change_access_id=#{change_access_id}"
    end
  end

  def invalid_documents_without_validation_request
    invalid_documents.reject { |x| replacement_document_validation_requests.where(old_document: x).any? }
  end

  def invalid_documents
    documents.active.invalidated
  end

  def result_present?
    [result_flag, result_heading, result_description, result_override].any?(&:present?)
  end

  def validation_requests
    (replacement_document_validation_requests + additional_document_validation_requests + other_change_validation_requests + red_line_boundary_change_validation_requests).sort_by(&:created_at).reverse
  end

  def cancelled_validation_requests
    validation_requests.filter(&:cancelled?).sort_by(&:cancelled_at).reverse
  end
  
  def open_description_change_requests
    description_change_validation_requests.where(state: "open")
  end

  # since we can't use the native scopes that AASM provides (because
  # #validation_requests is actually the method above rather than a
  # .has_many assocations), add some homemade methods to them.
  #
  # application.open_validation_requests => [reqs...]
  # application.open_validation_requests? => true/false
  %i[open pending closed].each do |state|
    selector = "#{state}_validation_requests"

    define_method selector do
      validation_requests.select(&:"#{state}?".to_sym)
    end

    define_method "#{selector}?" do
      send(selector).any?
    end
  end

  def last_validation_request_date
    closed_validation_requests.max_by(&:updated_at).updated_at
  end

  def payment_amount_pounds
    payment_amount.to_i / 100
  end

  def overdue_requests
    validation_requests.select(&:open?).select(&:overdue?)
  end

  def invalidation_response_due
    15.business_days.after(invalidated_at.to_date)
  end

  def parsed_application_type
    case application_type
    when "lawfulness_certificate"
      "Certificate of Lawfulness"
    when "full"
      "Full"
    else
      application_type.humanize
    end
  end

  def applicant_and_agent_email
    [agent_email, applicant_email].reject(&:blank?)
  end

  def agent_or_applicant_name
    if agent_first_name?
      "#{agent_first_name} #{agent_last_name}"
    else
      "#{applicant_first_name} #{applicant_last_name}"
    end
  end

  def policy_classes_editable
    errors.add(:policy_classes, "cannot be added at this stage") if policy_classes_changed? && !in_assessment?
  end

  def documents_for_decision_notice
    documents.for_display
  end
  
  def allows_only_one_open_description_change
    errors.add(:base, "An open description change already exists for this planning application") if open_description_change_requests.size > 1
  end

  private

  def set_key_dates
    self.expiry_date = 40.business_days.after(documents_validated_at || created_at)
    self.target_date = 35.business_days.after(documents_validated_at || created_at)
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
    errors.add(:planning_application, "Please select Yes or No") if decision.nil? && recommendations.any?
  end

  def applicant_or_agent_email
    errors.add(:base, "An applicant or agent email is required.") unless applicant_email? || agent_email?
  end
end
