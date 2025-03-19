# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  include StoreModel::NestedAttributes

  attribute :application_type_overrides, ApplicationTypeOverrides.to_array_type

  validates :application_type_overrides, store_model: {merge_errors: true}

  accepts_nested_attributes_for :application_type_overrides

  with_options dependent: :destroy do
    has_many :users
    has_many :planning_applications, -> { kept }
    has_many :constraints
    has_many :contacts
    has_many :informatives
    has_many :policy_areas
    has_many :policy_guidances
    has_many :policy_references
    has_many :requirements
    has_many :api_users
    has_many :application_types
  end

  with_options through: :planning_applications do
    has_many :audits
    has_many :consultations
    has_many :documents
    has_many :validation_requests
  end

  has_many :neighbour_responses, through: :consultations

  with_options presence: true do
    validates :council_code, :subdomain
    validates :short_name, :council_name
    validates :applicants_url
  end

  with_options format: {with: URI::HTTP::ABS_URI} do
    with_options allow_blank: true do
      validates :applicants_url
    end
  end

  with_options format: {with: URI::MailTo::EMAIL_REGEXP} do
    with_options allow_blank: true do
      validates :email_address
      validates :reviewer_group_email
      validates :press_notice_email
    end
  end

  validate :council_code_exists

  before_save :clear_notify_error_status
  before_update :set_active

  def signatory
    "#{signatory_name}, #{signatory_job_title}"
  end

  def notify_api_key
    super || Rails.configuration.default_notify_api_key
  end

  def letter_template_id
    super || Rails.configuration.default_letter_template_id
  end

  def notify_api_key_for_letters
    if Bops.env.production?
      notify_api_key
    else
      Rails.configuration.notify_letter_api_key
    end
  end

  def applicants_url
    if Bops.env.production?
      super
    else
      "https://#{subdomain}.#{Rails.configuration.applicants_base_url}"
    end
  end

  def public_register_base_url
    return super if super.present? && Bops.env.production?

    "https://#{subdomain}.#{Rails.configuration.applicants_base_url}"
  end

  def inactive?
    !active
  end

  def onboarding_status
    onboarded? ? "Completed" : onboarding_progress
  end

  ACTIVE_ATTRIBUTES = %w[email_address
    email_reply_to_id
    enquiries_paragraph
    feedback_email
    letter_template_id
    notify_api_key
    press_notice_email
    reviewer_group_email
    signatory_job_title
    signatory_name].freeze

  CREATION_ATTRIBUTES = %w[subdomain
    council_code
    council_name
    short_name
    applicants_url].freeze

  ONBOARDED_ATTRIBUTES = (CREATION_ATTRIBUTES + ACTIVE_ATTRIBUTES).freeze

  REDACTED_INFO = %w[notify_api_key
    reviewer_group_email
    applicants_url
    email_address].freeze

  HIDDEN_ATTRS = %W[email_reply_to_id
    letter_template_id].freeze

  def redacted?(onboarded_attribute)
    REDACTED_INFO.include?(onboarded_attribute)
  end

  def onboarded_attributes_list
    ONBOARDED_ATTRIBUTES
  end

  def hidden?(onboarded_attribute)
    HIDDEN_ATTRS.include?(onboarded_attribute)
  end

  def to_param
    subdomain
  end

  private

  def council_code_exists
    return true if plan_x?
    return true unless council_code_changed?

    errors.add(:council_code, "Please enter a valid council code") unless council_code == planning_data
  end

  def plan_x?
    council_code == "PlanX"
  end

  def planning_data
    @planning_data ||= Apis::PlanningData::Query.new.get_council_code(council_code)
  end

  def planning_data?
    !planning_data.nil?
  end

  def set_active
    self.active = active_attributes?
  end

  def active_attributes?
    attributes.select { |k, v| ACTIVE_ATTRIBUTES.include?(k) }.each_value.all?(&:present?)
  end

  def onboarded_attributes
    @onboarded_attributes ||= attributes.select(&method(:onboarded_attribute?))
  end

  def onboarded_attribute?(attribute, value)
    ONBOARDED_ATTRIBUTES.include?(attribute) && value.present?
  end

  def onboarded?
    onboarded_attributes.size == ONBOARDED_ATTRIBUTES.size
  end

  def onboarding_progress
    format("%d of %d", onboarded_attributes.size, ONBOARDED_ATTRIBUTES.size)
  end

  def clear_notify_error_status
    return if notify_error_status.blank?

    %i[notify_api_key letter_template_id email_reply_to_id].each do |attr|
      if will_save_change_to_attribute?(attr)
        self.notify_error_status = nil if notify_error_status == "bad_#{attr}"
      end
    end
  end
end
