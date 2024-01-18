# frozen_string_literal: true

class PlanningApplication < ApplicationRecord
  class SubmitRecommendationError < RuntimeError; end

  class WithdrawRecommendationError < RuntimeError; end

  class WithdrawOrCancelError < RuntimeError; end

  include Auditable

  include PlanningApplicationDecorator

  include PlanningApplicationStatus

  include PlanningApplication::Notification

  DAYS_TO_EXPIRE = 56
  DAYS_TO_EXPIRE_EIA = 112

  enum user_role: {applicant: 0, agent: 1, proxy: 2}

  enum decision: {granted: "granted", refused: "refused", granted_not_required: "granted_not_required"}

  with_options dependent: :destroy do
    has_many :audits, -> { by_created_at }, inverse_of: :planning_application
    has_many :documents, -> { by_created_at }, inverse_of: :planning_application

    has_many(
      :recommendations,
      -> { order :created_at },
      inverse_of: :planning_application
    )

    has_many :description_change_validation_requests
    has_many :replacement_document_validation_requests
    has_many :other_change_validation_requests
    has_many :fee_change_validation_requests
    has_many :additional_document_validation_requests
    has_many :red_line_boundary_change_validation_requests
    has_many :ownership_certificate_validation_requests
    has_many :notes, -> { by_created_at_desc }, inverse_of: :planning_application
    has_many :validation_requests
    has_many :assessment_details, -> { by_created_at_desc }, inverse_of: :planning_application
    has_many :permitted_development_rights, -> { order :created_at }, inverse_of: :planning_application
    has_many :planning_application_constraints
    has_many :planning_application_constraints_queries
    has_many :constraints, through: :planning_application_constraints, source: :constraint
    has_many :site_notices
    has_one :immunity_detail, required: false
    has_one :condition_set, required: false
    has_one :consultation, required: false
    has_one :proposal_measurement, required: false
    has_one :planx_planning_data, required: false
    has_one :press_notice, required: false
    has_one :local_policy, required: false
    has_one :fee_calculation, required: false
    has_one :ownership_certificate, required: false
    has_one :environment_impact_assessment, required: false

    has_many(
      :policy_classes,
      -> { order(:section) },
      dependent: :destroy,
      inverse_of: :planning_application
    )

    has_one :consistency_checklist, dependent: :destroy
  end

  delegate :consultation?, to: :application_type
  delegate :reviewer_group_email, to: :local_authority
  with_options prefix: true, allow_nil: true do
    delegate :email, to: :user
    delegate :name, to: :user
    delegate :required?, to: :press_notice
    delegate :required?, to: :site_notice
  end
  delegate :params_v1, to: :planx_planning_data, allow_nil: true
  delegate :params_v2, to: :planx_planning_data, allow_nil: true

  belongs_to :user, optional: true
  belongs_to :api_user, optional: true
  belongs_to :boundary_created_by, class_name: "User", optional: true
  belongs_to :local_authority
  belongs_to :application_type

  scope :by_created_at_desc, -> { order(created_at: :desc) }
  scope :by_application_type, -> { joins(:application_type).in_order_of(:name, ApplicationType::NAME_ORDER) }
  scope :by_status_order, -> { in_order_of(:status, PlanningApplication.aasm.states.map(&:name)) }
  scope :with_user, -> { preload(:user) }
  scope :for_user_and_null_users, ->(user_id) { where(user_id: [user_id, nil]) }
  scope :prior_approvals, -> { joins(:application_type).where(application_type: {name: :prior_approval}) }
  scope :accepted, -> { where.not(status: "pending") }

  before_validation :set_application_number, on: :create
  before_validation :set_reference, on: :create
  before_create :set_key_dates
  before_create :set_change_access_id
  after_create :set_ward_and_parish_information
  after_create :create_audit!
  after_create :update_measurements, if: :prior_approval?
  after_create :create_consultation!, if: :consultation?
  before_update :set_key_dates
  before_update lambda {
                  reset_validation_requests_update_counter!(red_line_boundary_change_validation_requests)
                }, if: :valid_red_line_boundary?
  before_update lambda {
                  reset_validation_requests_update_counter!(fee_change_validation_requests)
                }, if: :valid_fee?
  before_update :audit_update_application_type!, if: :application_type_id_changed?
  before_update :create_proposal_measurement, if: :changed_to_prior_approval?

  after_update :audit_updated!
  after_update :update_constraints
  after_update :address_or_boundary_geojson_updated?

  accepts_nested_attributes_for :recommendations
  accepts_nested_attributes_for :documents, reject_if: proc { |attributes| attributes["file"].blank? }
  accepts_nested_attributes_for :constraints
  accepts_nested_attributes_for :proposal_measurement
  accepts_nested_attributes_for :planx_planning_data

  WORK_STATUSES = %w[proposed existing].freeze

  PLANNING_APPLICATION_PERMITTED_KEYS = %w[address_1
    address_2
    applicant_first_name
    applicant_last_name
    applicant_phone
    applicant_email
    agent_first_name
    agent_last_name
    agent_phone
    agent_email
    county
    created_at(3i)
    created_at(2i)
    created_at(1i)
    description
    proposal_details
    payment_reference
    payment_amount
    postcode
    public_comment
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

  PROGRESS_STATUSES = %w[not_started in_progress complete].freeze

  private_constant :PLANNING_APPLICATION_PERMITTED_KEYS

  validates :work_status,
    inclusion: {in: WORK_STATUSES}
  validates :review_documents_for_recommendation_status,
    inclusion: {in: PROGRESS_STATUSES}
  validates :application_number, :reference, presence: true
  validates :payment_amount,
    :invalid_payment_amount,
    numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 1_000_000},
    allow_nil: true

  validate :applicant_or_agent_email
  validate :validated_at_date
  validate :public_comment_present
  validate :decision_with_recommendations
  validate :determination_date_is_not_in_the_future
  validate :user_is_non_administrator

  def payment_amount=(amount)
    fee_calculation.requested_fee = amount.to_s.delete("^0-9.-").to_d
    fee_calculation.save! if persisted?

    fee_calculation.requested_fee
  end

  def timestamp_status_change
    update("#{aasm.to_state}_at": Time.zone.now)
  end

  def days_from
    created_at.to_date.business_days_until(Time.previous_business_day(Date.current))
  end

  def days_left
    Date.current.business_days_until(expiry_date)
  end

  def days_overdue
    expiry_date.business_days_until(Time.previous_business_day(Date.current))
  end

  def reference_in_full
    @reference_in_full ||= "#{local_authority.council_code}-#{reference}"
  end

  def application_number
    self[:application_number].to_s.rjust(5, "0")
  end

  def reviewer_disagrees_with_assessor?
    to_be_reviewed?
  end

  def assessor_decision_updated?
    awaiting_determination? && recommendations.count > 1
  end

  def reviewer_decision_updated?
    to_be_reviewed? && recommendations.count > 1
  end

  def agent?
    agent_first_name? || agent_last_name? || agent_phone? || agent_email?
  end

  def applicant?
    applicant_first_name? || applicant_last_name? || applicant_phone? || applicant_email?
  end

  def review_complete?
    to_be_reviewed? || determined?
  end

  def recommendable?
    true unless determined? || returned? || withdrawn? || closed? || invalidated? || not_started?
  end

  def in_progress?
    true unless determined? || returned? || withdrawn? || closed?
  end

  def validated?
    true unless not_started? || invalidated?
  end

  def can_validate?
    true unless awaiting_determination? || determined? || returned? || withdrawn? || closed?
  end

  def validation_complete?
    !not_started?
  end

  def can_assess?
    assessment_in_progress? || in_assessment? || to_be_reviewed?
  end

  def closed_or_cancelled?
    determined? || returned? || withdrawn? || closed?
  end

  def assessment_complete?
    (validation_complete? && pending_review? && !assessment_in_progress?) || awaiting_determination? || determined?
  end

  def can_submit_recommendation?
    assessment_complete? && (in_assessment? || to_be_reviewed?)
  end

  def submit_recommendation_complete?
    awaiting_determination? || determined?
  end

  def can_review_assessment?
    awaiting_determination? && Current.user.reviewer?
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

  def existing_or_new_recommendation
    recommendation || recommendations.build
  end

  def proposal_details
    Array(super).each_with_index.map do |hash, index|
      ProposalDetail.new(hash, index)
    end
  end

  def flagged_proposal_details
    proposal_details.select do |proposal_detail|
      proposal_detail.flags.include?(result_flag)
    end
  end

  def immune_proposal_details
    proposal_details.select do |proposal_detail|
      proposal_detail.flags == ["Planning permission / Immune"]
    end
  end

  def find_proposal_detail(question)
    proposal_details.select { |detail| detail.question == question }
  end

  def cil_liability_questions
    [
      "How much new floor area is being added to the house?",
      "How much new floor area is being created?"
    ]
  end

  def cil_liability_planx_answers
    cil_liability_questions.filter_map { |q| find_proposal_detail(q) }.flatten
  end

  def cil_liability_proposal_detail
    cil_liability_planx_answers.first
  end

  def cil_liability_planx_answer?
    cil_liability_planx_answers.present?
  end

  def likely_cil_liable?
    cil_liability_planx_answer? && cil_liability_proposal_detail&.response_values&.first != "Less than 100m²"
  end

  def secure_change_url
    params = {planning_application_id: id, change_access_id:}
    "#{local_authority.applicants_url}/validation_requests?#{params.to_query}"
  end

  def site_notice_link
    "#{local_authority.applicants_url}/planning_applications/#{id}/site_notices/download"
  end

  def last_site_notice_audit
    audits.where(activity_type: "site_notice_created").order(:created_at).last
  end

  def last_site_notice
    site_notices.order(:created_at).last
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

  def invalidation_response_due
    15.business_days.after(invalidated_at.to_date)
  end

  def applicant_and_agent_email
    [agent_email, applicant_email].compact_blank
  end

  def agent_or_applicant_name
    if agent_first_name?
      "#{agent_first_name} #{agent_last_name}"
    else
      "#{applicant_first_name} #{applicant_last_name}"
    end
  end

  def documents_for_decision_notice
    documents.for_display
  end

  def received_at
    super || (Time.next_immediate_business_day(created_at) if created_at)
  end

  def valid_from
    return nil unless validated?

    if validation_requests.closed.any?
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
        audit_comment: {assessor_comment: recommendation.assessor_comment}.to_json
      )
    end

    send_update_notification_to_reviewers
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

  def assign!(user)
    transaction do
      update!(user:)
      audit!(activity_type: "assigned", activity_information: user&.name)

      if application_type_name == "prior_approval"
        send_assigned_notification_to_assessor
      else
        send_update_notification_to_assessor
      end
    end
  end

  def determination_date
    super || Time.zone.today
  end

  def audit_boundary_geojson!(status)
    audit!(activity_type: "red_line_#{status}", audit_comment: "Red line drawing #{status}")
  end

  def constraints_checked!
    transaction do
      update!(constraints_checked: true)
      audit!(activity_type: "constraints_checked")
    end
  end

  def default_validated_at
    self.validated_at ||= Time.next_immediate_business_day(valid_from_date)
  end

  def assessment_submitted?
    assessment_complete? || to_be_reviewed?
  end

  def no_policy_classes_after_assessment?
    assessment_complete? && policy_classes.none?
  end

  def policy_class?(section)
    policy_classes.pluck(:section).include?(section)
  end

  def planning_history_enabled?
    Rails.configuration.planning_history_enabled
  end

  def rejected_assessment_detail(category:)
    assessment_details.where(
      category:,
      review_status: :complete,
      reviewer_verdict: :rejected
    ).first
  end

  AssessmentDetail.categories.each_key do |category|
    define_method(category) do
      assessment_details.where(category:).first
    end

    define_method(:"existing_or_new_#{category}") do
      send(category) || assessment_details.new(category:)
    end
  end

  Recommendation.statuses.each_key do |status|
    delegate("#{status}?", to: :recommendation, prefix: true, allow_nil: true)
  end

  def recommendation
    @recommendation ||= recommendations.last
  end

  def last_recommendation_accepted?
    return false unless recommendation

    recommendation.accepted?
  end

  def permitted_development_right
    permitted_development_rights.last
  end

  def updates_required?
    assessment_details_for_review.any?(&:update_required?) ||
      permitted_development_right&.update_required? ||
      policy_classes.any?(&:update_required?)
  end

  def review_in_progress?
    recommendation.review_in_progress? ||
      assessment_details_for_review.any?(&:reviewer_verdict) ||
      policy_classes.any?(&:review_policy_class) ||
      permitted_development_right&.review_started?
  end

  def assessment_details_for_review
    ReviewAssessmentDetailsForm::ASSESSMENT_DETAILS.filter_map do |assessment_detail|
      send(assessment_detail)
    end
  end

  def can_clone?
    !Bops.env.production?
  end

  def withdraw_or_cancel!(status, comment, document_params)
    event = withdraw_or_cancel_event(status)

    transaction do
      update!(document_params) if document_params
      send(event, status.to_sym, comment)
    end
  rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition => e
    raise WithdrawOrCancelError, e.message
  end

  def user_is_non_administrator
    return unless user_id_changed?
    return unless user&.administrator?

    errors.add(:user, "You cannot assign a planning application to an adminstrator")
  end

  def possibly_immune?
    immunity_detail.present?
  end

  def address_or_boundary_or_constraints_updated?
    updated_address_or_boundary_geojson || changed_constraints.present?
  end

  def rear_wall_length
    find_proposal_detail("Exactly how far will the new addition extend beyond the back wall of the original house?")
      &.first&.response_values&.first
  end

  def max_height_extension
    find_proposal_detail("What is the exact height of the extension?")&.first&.response_values&.first
  end

  def eave_height_extension
    find_proposal_detail("Exactly how high are the eaves of the extension?")&.first&.response_values&.first
  end

  def neighbour_addresses
    proposal_details.select { |detail| detail.question.include? "adjoining property" }&.map(&:response_values)&.flatten
  end

  def neighbour_addresses_inline
    neighbour_addresses.map do |address|
      address.gsub(/[,\s]{2,}/, ", ")
    end
  end

  def mark_legislation_as_checked!
    transaction do
      update!(legislation_checked: true)
      audit!(activity_type: "legislation_checked")
    end
  end

  def latitude
    super || lonlat.try(:y)
  end

  def longitude
    super || lonlat.try(:x)
  end

  def site_notice
    site_notices.by_created_at_desc.first
  end

  def site_notice_needs_displayed_at?
    site_notice_required? && site_notice.displayed_at.nil?
  end

  def press_notice_needs_published_at?
    press_notice_required? && press_notice.published_at.nil?
  end

  def address
    [address_1, address_2, town, county, postcode].compact_blank.join(", ")
  end

  delegate :name, to: :application_type, prefix: true

  ApplicationType::NAME_ORDER.each do |name|
    define_method :"#{name}?" do
      name == application_type_name
    end
  end

  def condition_set
    super || create_condition_set!
  end

  def pending_validation_requests?
    validation_requests.where(state: "pending").any?
  end

  def pending_validation_requests
    validation_requests.where(state: "pending")
  end

  def reset_validation_requests_update_counter!(requests)
    return unless validation_requests.any?

    requests.pre_validation.where(update_counter: true).each(&:reset_update_counter!)
  end

  def latest_rejected_description_change
    description_change_validation_requests.order(created_at: :desc).find(&:rejected?)
  end

  def latest_auto_closed_description_request
    description_change_validation_requests.where(auto_closed: true).order(created_at: :desc).last
  end

  def last_validation_request_date
    validation_requests.closed.max_by(&:updated_at).updated_at
  end

  def all_open_post_validation_requests
    validation_requests.open.post_validation
  end

  def no_open_post_validation_requests?
    validation_requests.open.post_validation.none?
  end

  def open_post_validation_requests
    validation_requests.open.post_validation
  end

  def open_post_validation_requests?
    validation_requests.open.post_validation.any?
  end

  def other_change_validation_request
    other_change_validation_requests.order(:created_at).last
  end

  def fee_change_validation_request
    fee_change_validation_requests.order(:created_at).last
  end

  def description_change_validation_request
    description_change_validation_requests.order(:created_at).last
  end

  def red_line_boundary_change_validation_request
    red_line_boundary_change_validation_requests.order(:created_at).last
  end

  def additional_document_validation_request
    additional_document_validation_requests.order(:created_at).last
  end

  def replacement_document_validation_request
    replacement_document_validation_requests.order(:created_at).last
  end

  def overdue_validation_requests
    validation_requests.open.select(&:overdue?)
  end

  def check_permitted_development_rights?
    application_type.features.permitted_development_rights?
  end

  def review_permitted_development_rights?
    check_permitted_development_rights? && permitted_development_right
  end

  def payment_amount
    (fee_calculation&.requested_fee || fee_calculation&.payable_fee).to_d
  end

  def fee_calculation
    super || create_fee_calculation
  end

  def generate_document_tabs(tabs = Document::DEFAULT_TABS)
    all_documents = documents.with_file_attachment

    tabs.map do |tab|
      documents = (tab == "All") ? all_documents : filter_documents_for_tab(all_documents, tab)

      {title: tab, id: tab.parameterize, content: tab, records: documents}
    end
  end

  def environment_impact_assessment_status
    if environment_impact_assessment.present?
      environment_impact_assessment.required ? :required : :not_required
    else
      :not_started
    end
  end

  def modify_expiry_date
    if environment_impact_assessment.required?
      self.expiry_date = DAYS_TO_EXPIRE_EIA.days.after(validated_at || received_at)
    else
      set_key_dates
    end

    save
  end

  private

  def create_fee_calculation
    calc = if planx_planning_data&.params_v2.present?
      FeeCalculation.from_odp_data(planx_planning_data.params_v2)
    elsif planx_planning_data&.params_v1.present?
      FeeCalculation.from_planx_data(JSON.parse(planx_planning_data.params_v1, symbolize_names: true))
    else
      FeeCalculation.new
    end

    calc.planning_application = self
    calc.save! if persisted?
    calc
  end

  def update_measurements
    ProposalMeasurement.create!(
      planning_application: self,
      depth: rear_wall_length.to_f,
      max_height: max_height_extension.to_f,
      eaves_height: eave_height_extension.to_f
    )
  end

  def set_reference
    self.reference = [
      Date.current.strftime("%y"),
      application_number,
      application_type_code
    ].join("-")
  end

  def set_key_dates
    return if environment_impact_assessment&.required?

    self.expiry_date = DAYS_TO_EXPIRE.days.after(validated_at || received_at)
    self.target_date = 35.days.after(validated_at || received_at)
  end

  def set_change_access_id
    self.change_access_id = SecureRandom.hex(15)
  end

  def set_ward_and_parish_information
    return if postcode.blank?

    ward_type, ward, parish_name = Apis::Mapit::Query.new.fetch(postcode)

    self.ward_type = ward_type
    self.ward = ward
    self.parish_name = parish_name
    save!
  end

  def validated_at_date
    return unless in_assessment? && !validated_at.to_date.is_a?(Date)

    errors.add(:planning_application, "Please enter a valid date")
  end

  def validation_date?
    !validated_at.nil?
  end

  def public_comment_present
    errors.add(:public_comment, :blank) if public_comment.blank? && recommendations.any?
  end

  def decision_present?
    decision.present?
  end

  def decision_with_recommendations
    errors.add(:decision, :blank) if decision.blank? && recommendations.any?
  end

  def applicant_or_agent_email
    errors.add(:base, "An applicant or agent email is required.") unless applicant_email? || agent_email?
  end

  def create_audit!
    audit!(activity_type: "created", activity_information: Current.api_user&.name || Current.user&.name)
  end

  def audit_updated!
    return unless saved_changes?

    saved_changes.keys.intersection(PLANNING_APPLICATION_PERMITTED_KEYS).map do |attribute_name|
      next if saved_change_to_attribute(attribute_name).all? { |value| value.blank? || value.try(:zero?) }

      attribute_to_audit(attribute_name)
    end
  end

  def address_or_boundary_geojson_updated?
    return if updated_address_or_boundary_geojson

    return unless saved_changes.keys.intersection(ADDRESS_AND_BOUNDARY_GEOJSON_FIELDS).any?

    update!(updated_address_or_boundary_geojson: true)
  end

  def update_constraints
    return unless saved_changes.include? "boundary_geojson"

    ConstraintQueryUpdateJob.perform_later(planning_application: self)
  end

  def attribute_to_audit(attribute_name)
    audit!(activity_type: "updated",
      activity_information: attribute_name.humanize,
      audit_comment: audit_comment(attribute_name))
  end

  def audit_comment(attribute_name)
    original_attribute = saved_change_to_attribute(attribute_name).first
    new_attribute = saved_change_to_attribute(attribute_name).second

    "Changed from: #{original_attribute} \r\n Changed to: #{new_attribute}"
  end

  def audit_update_application_type!
    old_application_type = ApplicationType.find(changes["application_type_id"].first)
    old_reference = reference

    set_application_number
    set_reference

    audit!(
      activity_type: "updated",
      activity_information: "Application type",
      audit_comment:
        "Application type changed from: #{old_application_type.full_name} / Changed to: #{application_type.full_name},
         Reference changed from #{old_reference} to #{reference}"
    )
  end

  def determination_date_is_not_in_the_future
    return unless determination_date_changed?

    return unless determination_date >= Time.zone.tomorrow

    errors.add(:determination_date, "Determination date must be today or in the past")
  end

  def set_application_number
    local_authority_planning_applications = local_authority.planning_applications

    self.application_number = if local_authority_planning_applications.any?
      local_authority_planning_applications.maximum(:application_number) + 1
    else
      100
    end
  end

  def application_type_code
    I18n.t(work_status, scope: "application_type_codes.#{application_type&.name}")
  end

  def valid_from_date
    if validation_requests.closed.any?
      validation_requests.closed.max_by(&:updated_at).updated_at
    else
      created_at
    end
  end

  def withdraw_or_cancel_event(status)
    case status
    when "withdrawn"
      "withdraw!"
    when "returned"
      "return!"
    when "closed"
      "close!"
    else
      raise ArgumentError, "The status provided: #{status} is not valid"
    end
  end

  def changed_to_prior_approval?
    application_type_changed? && application_type.name == "prior_approval"
  end

  def create_proposal_measurement
    ProposalMeasurement.create(planning_application: self, depth: 0, max_height: 0, eaves_height: 0)
  end

  def filter_documents_for_tab(documents, tab)
    tags = Document::TAGS_MAP[tab]

    documents.select { |document| (tags & document.tags).any? }
  end
end
