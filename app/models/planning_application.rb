# frozen_string_literal: true

require "aasm"

class PlanningApplication < ApplicationRecord
  include PlanningApplicationDecorator

  include AASM

  include AuditableModel

  enum application_type: { lawfulness_certificate: 0, full: 1 }

  with_options dependent: :destroy do
    has_many :audits, -> { order(created_at: :asc) }, inverse_of: :planning_application
    has_many :documents
    has_many :recommendations
    has_many :description_change_validation_requests
    has_many :replacement_document_validation_requests
    has_many :other_change_validation_requests
    has_many :additional_document_validation_requests
    has_many :red_line_boundary_change_validation_requests
    has_many :notes, -> { by_created_at_desc }, inverse_of: :planning_application
  end

  belongs_to :user, optional: true
  belongs_to :api_user, optional: true
  belongs_to :boundary_created_by, class_name: "User", optional: true
  belongs_to :local_authority

  before_create :set_key_dates
  before_create :set_change_access_id
  after_create :audit_created
  before_update :set_key_dates
  after_update :audit_update_actions

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

  scope :not_started_and_invalid, -> { where("status = 'not_started' OR status = 'invalidated'") }
  scope :under_assessment, -> { where("status = 'in_assessment' OR status = 'awaiting_correction'") }
  scope :closed, -> { where("status = 'determined' OR status = 'withdrawn' OR status = 'returned'") }

  attribute :policy_classes, :policy_class, array: true

  aasm.attribute_name :status

  aasm no_direct_assignment: true do
    state :not_started, initial: true
    state :invalidated, display: "invalid"
    state :in_assessment
    state :awaiting_determination
    state :awaiting_correction
    state :determined
    state :returned
    state :withdrawn

    event :start do
      transitions from: %i[not_started invalidated in_assessment], to: :in_assessment, guard: :has_validation_date?

      after do
        audit("started")
      end
    end

    event :assess do
      transitions from: %i[in_assessment awaiting_correction], to: :awaiting_determination, guard: :decision_present?

      after do
        audit("assessed", recommendations.last&.assessor_comment)
      end
    end

    event :invalidate do
      transitions from: :not_started, to: :invalidated, guard: :pending_validation_requests? do
        after { pending_validation_requests.each(&:mark_as_sent!) }

        after do
          request_names = open_validation_requests.map(&:audit_name)
          audit("validation_requests_sent", nil, request_names.join(", "))
          audit("invalidated")
        end
      end
    end

    event :determine do
      transitions from: :awaiting_determination, to: :determined

      after do
        audit("determined", "Application #{decision}")
      end
    end

    event :request_correction do
      transitions from: :awaiting_determination, to: :awaiting_correction

      after do
        audit("challenged", recommendations.last.reviewer_comment)
      end
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
      after do
        audit("returned", cancellation_comment)
      end
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
      after do
        audit("withdrawn", cancellation_comment)
      end
    end

    after_all_transitions :timestamp_status_change # FIXME: https://github.com/aasm/aasm#timestamps
  end

  def audit_created
    audit("created", nil, Current.user&.name || Current.api_user&.name)
  end

  def audit_update_actions
    saved_changes.keys.map do |attribute_name|
      case attribute_name
      when "constraints"
        prev_arr, new_arr = saved_changes[:constraints]

        attr_removed = prev_arr - new_arr
        attr_added = new_arr - prev_arr

        attr_added.each { |attr| audit("constraint_added", attr) }
        attr_removed.each { |attr| audit("constraint_removed", attr) }
      when "boundary_geojson"
        audit("red_line_updated", "Red line drawing updated")
      else
        unless attribute_name.eql?("updated_at")
          audit("updated",
                "Changed from: #{saved_change_to_attribute(attribute_name).first}
                  \r\n Changed to: #{saved_change_to_attribute(attribute_name).second}",
                attribute_name.humanize)
        end
      end
    end
  end

  def timestamp_status_change
    update("#{aasm.to_state}_at": Time.zone.now)
  end

  def days_left
    Date.current.business_days_until(expiry_date)
  end

  def days_overdue
    expiry_date.business_days_until(Date.current)
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

  def proposal_details
    JSON.parse(self[:proposal_details] || "[]", object_class: OpenStruct)
  end

  def proposal_details_with_metadata
    proposal_details.select do |proposal|
      proposal.responses.any? { |element| element.metadata.present? }
    end
  end

  def proposal_details_with_flags
    proposal_details_with_metadata.select do |proposal|
      proposal.responses.any? { |element| element.metadata.flags.present? }
    end
  end

  def flagged_proposal_details(flag)
    proposal_details_with_flags.select do |proposal|
      proposal.responses.any? { |element| element&.metadata&.flags&.include?(flag) }
    end
  end

  def secure_change_url
    protocol = Rails.env.production? ? "https" : "http"

    "#{protocol}://#{local_authority.subdomain}.#{ENV['APPLICANTS_APP_HOST']}/validation_requests?planning_application_id=#{id}&change_access_id=#{change_access_id}"
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
    description_change_validation_requests.open
  end

  def latest_auto_closed_description_request
    description_change_validation_requests.order(created_at: :desc).select(&:auto_closed?).first
  end

  def latest_rejected_description_change
    description_change_validation_requests.order(created_at: :desc).select(&:rejected?).first
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

  def received_at
    Time.next_immediate_business_day(created_at)
  end

  # FIXME: it is unclear how the constraits are parsed/mapped from an
  # API request. I was told (RIPA Slack, 12/21) that the list was:
  #
  # article4
  # article4.buckinghamshire.officetoresi
  # article4.buckinghamshire.poultry
  # article4.lambeth.caz
  # article4.lambeth.kiba
  # article4.lambeth.fentiman
  # article4.lambeth.streatham
  # article4.lambeth.stockwell
  # article4.lambeth.leigham
  # article4.lambeth.stmarks
  # article4.lambeth.parkHall
  # article4.lambeth.lansdowne
  # article4.lambeth.albert
  # article4.lambeth.hydeFarm
  # article4.southwark.sunray
  # listed
  # designated
  # designated.conservationArea
  # designated.conservationArea.lambeth.churchRoad
  # designated.AONB
  # designated.nationalPark
  # designated.broads
  # designated.WHS
  # designated.monument
  # tpo
  # nature.SSSI
  #
  # but these do not map to all the constraints we have (ex: military
  # zone). Until that is figured (and please ad some integration tests
  # around it), just assume plain-text constraints rather than a
  # key-value mapping.
  def defined_constraints
    I18n.t("constraints").values.flatten
  end

  def custom_constraints
    constraints.difference(defined_constraints)
  end

  def valid_from
    return nil unless validated?

    if closed_validation_requests.any?
      Time.next_immediate_business_day(last_validation_request_date)
    else
      received_at
    end
  end

  def assign(user)
    self.user = user

    audit("assigned", nil, self.user&.name)
  end

  private

  def set_key_dates
    self.expiry_date = 40.days.after(documents_validated_at || received_at)
    self.target_date = 35.days.after(documents_validated_at || received_at)
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
