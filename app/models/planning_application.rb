# frozen_string_literal: true

class PlanningApplication < ApplicationRecord
  class SubmitRecommendationError < RuntimeError; end

  class WithdrawRecommendationError < RuntimeError; end

  include Auditable

  include PlanningApplicationDecorator

  include PlanningApplicationStatus

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

  after_create :set_ward_information
  after_create :create_audit!
  before_update :set_key_dates
  after_update :audit_updated!
  after_update :address_or_boundary_geojson_updated?

  WORK_STATUSES = %w[proposed existing].freeze

  PLANNING_APPLICATION_PERMITTED_KEYS = %w[address_1
                                           address_2
                                           application_type
                                           applicant_first_name
                                           applicant_last_name
                                           applicant_phone
                                           applicant_email
                                           agent_first_name
                                           agent_last_name
                                           agent_phone
                                           agent_email
                                           county
                                           constraints
                                           created_at(3i)
                                           created_at(2i)
                                           created_at(1i)
                                           description
                                           proposal_details
                                           payment_reference
                                           postcode
                                           town
                                           uprn
                                           work_status].freeze

  ADDRESS_AND_BOUNDARY_GEOJSON_FIELDS = %w[address_1
                                           address_2
                                           county
                                           postcode
                                           town
                                           uprn
                                           boundary_geojson].freeze

  private_constant :PLANNING_APPLICATION_PERMITTED_KEYS

  validates :work_status,
            inclusion: { in: WORK_STATUSES,
                         message: "Work Status should be proposed or existing" }
  validates :application_type, presence: true

  validate :applicant_or_agent_email
  validate :documents_validated_at_date
  validate :public_comment_present
  validate :decision_with_recommendations
  validate :policy_classes_editable
  validate :determination_date_is_not_in_the_future

  attribute :policy_classes, :policy_class, array: true

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
    true unless determined? || returned? || withdrawn? || closed? || invalidated? || not_started?
  end

  def in_progress?
    true unless determined? || returned? || withdrawn? || closed?
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
    true unless awaiting_determination? || determined? || returned? || withdrawn? || closed?
  end

  def validation_complete?
    !not_started?
  end

  def can_assess?
    assessment_in_progress? || in_assessment? || awaiting_correction?
  end

  def closed_or_cancelled?
    determined? || returned? || withdrawn? || closed?
  end

  def assessment_complete?
    (validation_complete? && pending_review? && !assessment_in_progress?) || awaiting_determination? || determined?
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

  def submit_recommendation!
    transaction do
      submit!

      Audit.create!(
        planning_application_id: id,
        user: Current.user,
        activity_type: "submitted",
        audit_comment: { assessor_comment: recommendations.last.assessor_comment }.to_json
      )
    end
  rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
    raise SubmitRecommendationError, e.message
  end

  def withdraw_last_recommendation!
    transaction do
      withdraw_recommendation!

      Audit.create!(
        planning_application_id: id,
        user: Current.user,
        activity_type: "withdrawn_recommendation"
      )
    end
  rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
    raise WithdrawRecommendationError, e.message
  end

  def assign(user)
    self.user = user

    audit!(activity_type: "assigned", activity_information: self.user&.name)
  end

  def determination_date
    super || Time.zone.today
  end

  def audit_boundary_geojson!(status)
    audit!(activity_type: "red_line_#{status}", audit_comment: "Red line drawing #{status}")
  end

  def audit_recommendation_approved!
    audit!(activity_type: "approved", audit_comment: recommendations.last.reviewer_comment)
  end

  private

  def set_key_dates
    self.expiry_date = 56.days.after(documents_validated_at || received_at)
    self.target_date = 35.days.after(documents_validated_at || received_at)
  end

  def set_change_access_id
    self.change_access_id = SecureRandom.hex(15)
  end

  def set_ward_information
    return if postcode.blank?

    ward_type, ward = Apis::Mapit::Query.new.fetch(postcode)

    self.ward_type = ward_type
    self.ward = ward
    save!
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

  def create_audit!
    audit!(activity_type: "created", activity_information: Current.api_user&.name || Current.user&.name)
  end

  def audit_updated!
    if saved_changes?
      saved_changes.keys.intersection(PLANNING_APPLICATION_PERMITTED_KEYS).map do |attribute_name|
        next if saved_change_to_attribute(attribute_name).all?(&:blank?)

        attribute_to_audit(attribute_name)
      end
    end
  end

  def address_or_boundary_geojson_updated?
    return if updated_address_or_boundary_geojson

    if saved_changes.keys.intersection(ADDRESS_AND_BOUNDARY_GEOJSON_FIELDS).any?
      update!(updated_address_or_boundary_geojson: true)
    end
  end

  def attribute_to_audit(attribute_name)
    if attribute_name.eql?("constraints")
      audit_constraits!(saved_changes)
    else
      audit!(activity_type: "updated",
             activity_information: attribute_name.humanize,
             audit_comment: "Changed from: #{saved_change_to_attribute(attribute_name).first} \r\n Changed to: #{saved_change_to_attribute(attribute_name).second}")
    end
  end

  def audit_constraits!(saved_changes)
    prev_arr, new_arr = saved_changes[:constraints]

    attr_removed = prev_arr - new_arr
    attr_added = new_arr - prev_arr

    attr_added.each { |attr| audit!(activity_type: "constraint_added", audit_comment: attr) }
    attr_removed.each { |attr| audit!(activity_type: "constraint_removed", audit_comment: attr) }
  end

  def determination_date_is_not_in_the_future
    return unless determination_date_changed?

    if determination_date >= Time.zone.tomorrow
      errors.add(:determination_date, "Determination date must be today or in the past")
    end
  end
end
