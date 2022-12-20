# frozen_string_literal: true

class PlanningApplication < ApplicationRecord
  class SubmitRecommendationError < RuntimeError; end

  class WithdrawRecommendationError < RuntimeError; end

  include Auditable

  include PlanningApplicationDecorator

  include PlanningApplicationStatus

  include PlanningApplication::ValidationRequests

  include PlanningApplication::Notification

  DAYS_TO_EXPIRE = 56

  enum application_type: { lawfulness_certificate: 0, full: 1 }

  enum user_role: { applicant: 0, agent: 1, proxy: 2 }

  with_options dependent: :destroy do
    has_many :audits, -> { by_created_at }, inverse_of: :planning_application
    has_many :documents, -> { with_file_attachment.by_created_at }, inverse_of: :planning_application

    has_many(
      :recommendations,
      -> { order :created_at },
      inverse_of: :planning_application
    )

    has_many :consultees, dependent: :destroy
    has_many :description_change_validation_requests
    has_many :replacement_document_validation_requests
    has_many :other_change_validation_requests
    has_many :fee_item_validation_requests, -> { fee_item }, class_name: "OtherChangeValidationRequest", inverse_of: :planning_application
    has_many :additional_document_validation_requests
    has_many :red_line_boundary_change_validation_requests
    has_many :notes, -> { by_created_at_desc }, inverse_of: :planning_application
    has_many :requests, class_name: "ValidationRequest"
    has_many :assessment_details, -> { by_created_at_desc }, inverse_of: :planning_application
    has_many :permitted_development_rights, -> { order :created_at }, inverse_of: :planning_application

    has_many(
      :policy_classes,
      -> { order(:section) },
      dependent: :destroy,
      inverse_of: :planning_application
    )

    has_one :consistency_checklist, dependent: :destroy
  end

  delegate :reviewer_group_email, to: :local_authority
  delegate :email, to: :user, prefix: true, allow_nil: true
  delegate :name, to: :user, prefix: true, allow_nil: true

  belongs_to :user, optional: true
  belongs_to :api_user, optional: true
  belongs_to :boundary_created_by, class_name: "User", optional: true
  belongs_to :local_authority

  scope :by_created_at_desc, -> { order(created_at: :desc) }
  scope :with_user, -> { preload(:user) }
  scope :for_user_and_null_users, ->(user_id) { where(user_id: [user_id, nil]) }

  before_validation :set_application_number, on: :create
  before_validation :set_reference, on: :create
  before_create :set_key_dates
  before_create :set_change_access_id
  after_create :set_ward_and_parish_information
  after_create :create_audit!
  before_update :set_key_dates
  before_update -> { reset_validation_requests_update_counter!(red_line_boundary_change_validation_requests) }, if: :valid_red_line_boundary?
  before_update -> { reset_validation_requests_update_counter!(fee_item_validation_requests) }, if: :valid_fee?
  after_update :audit_updated!
  after_update :address_or_boundary_geojson_updated?

  accepts_nested_attributes_for :recommendations

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
            inclusion: { in: WORK_STATUSES }
  validates :review_documents_for_recommendation_status,
            inclusion: { in: PROGRESS_STATUSES }
  validates :application_type, :application_number, :reference, presence: true
  validates :payment_amount,
            :invalid_payment_amount,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1_000_000 },
            allow_nil: true

  validate :applicant_or_agent_email
  validate :validated_at_date
  validate :public_comment_present
  validate :decision_with_recommendations
  validate :determination_date_is_not_in_the_future

  def payment_amount=(amount)
    self[:payment_amount] = amount.to_s.delete("^0-9.-").to_d
  end

  def timestamp_status_change
    update("#{aasm.to_state}_at": Time.zone.now)
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
    JSON.parse(self[:proposal_details] || "[]", object_class: OpenStruct)
  end

  def flagged_proposal_details
    proposal_details.select do |proposal_detail|
      proposal_detail.responses.any? do |response|
        response.metadata&.flags&.include?(result_flag)
      end
    end
  end

  def secure_change_url
    protocol = Rails.env.production? ? "https" : "http"

    public_url_enabled? ? "#{protocol}://#{public_url}" : "#{protocol}://#{internal_url}"
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
        audit_comment: { assessor_comment: recommendation.assessor_comment }.to_json
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

  def assign(user)
    self.user = user
    audit!(activity_type: "assigned", activity_information: self.user&.name)
    send_update_notification_to_assessor
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
    self.validated_at ||= if closed_validation_requests.present?
                            last_validation_request_date
                          else
                            created_at
                          end
  end

  def assessment_submitted?
    assessment_complete? || awaiting_correction?
  end

  def no_policy_classes_after_assessment?
    assessment_complete? && policy_classes.none?
  end

  def has_policy_class?(section)
    policy_classes.pluck(:section).include?(section)
  end

  def planning_history_enabled?
    ENV.fetch("PLANNING_HISTORY_ENABLED", "false") == "true"
  end

  def rejected_assessment_detail(category:)
    assessment_details.where(
      category: category,
      review_status: :complete,
      reviewer_verdict: :rejected
    ).first
  end

  AssessmentDetail.categories.each_key do |category|
    define_method(category) do
      assessment_details.where(category: category).first
    end

    define_method("existing_or_new_#{category}") do
      send(category) || assessment_details.new(category: category)
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
    AssessmentDetailsReview::ASSESSMENT_DETAILS.filter_map do |assessment_detail|
      send(assessment_detail)
    end
  end

  private

  def set_reference
    self.reference = [
      Date.current.strftime("%y"),
      application_number,
      application_type_code
    ].join("-")
  end

  def set_key_dates
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

  def has_validation_date?
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
      next if saved_change_to_attribute(attribute_name).all?(&:blank?)

      attribute_to_audit(attribute_name)
    end
  end

  def address_or_boundary_geojson_updated?
    return if updated_address_or_boundary_geojson

    return unless saved_changes.keys.intersection(ADDRESS_AND_BOUNDARY_GEOJSON_FIELDS).any?

    update!(updated_address_or_boundary_geojson: true)
  end

  def attribute_to_audit(attribute_name)
    if attribute_name.eql?("constraints")
      audit_constraints!(saved_changes)
    else
      audit!(activity_type: "updated",
             activity_information: attribute_name.humanize,
             audit_comment: audit_comment(attribute_name))
    end
  end

  def audit_comment(attribute_name)
    original_attribute = saved_change_to_attribute(attribute_name).first
    new_attribute = saved_change_to_attribute(attribute_name).second

    if attribute_name == "payment_amount"
      "Changed from: £#{format('%.2f', original_attribute.to_f)} \r\n Changed to: £#{format('%.2f', new_attribute.to_f)}"
    else
      "Changed from: #{original_attribute} \r\n Changed to: #{new_attribute}"
    end
  end

  def audit_payment_amount
    audit_constraints!(saved_changes) if attribute_name.eql?("constraints")
  end

  def audit_constraints!(saved_changes)
    prev_arr, new_arr = saved_changes[:constraints]

    attr_removed = prev_arr - new_arr
    attr_added = new_arr - prev_arr

    attr_added.each { |attr| audit!(activity_type: "constraint_added", audit_comment: attr) }
    attr_removed.each { |attr| audit!(activity_type: "constraint_removed", audit_comment: attr) }
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
    I18n.t(work_status, scope: "application_type_codes.#{application_type}")
  end

  def public_url
    "#{ENV['APPLICANTS_APP_HOST']}.#{local_authority.subdomain}.gov.uk/validation_requests?planning_application_id=#{id}&change_access_id=#{change_access_id}"
  end

  def internal_url
    "#{local_authority.subdomain}.#{ENV['APPLICANTS_APP_HOST']}/validation_requests?planning_application_id=#{id}&change_access_id=#{change_access_id}"
  end

  def public_url_enabled?
    ENV.fetch("PUBLIC_URL_ENABLED", "false") == "true"
  end
end
