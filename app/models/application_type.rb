# frozen_string_literal: true

class ApplicationType < ApplicationRecord
  NAME_ORDER = %w[prior_approval planning_permission lawfulness_certificate other].freeze
  ODP_APPLICATION_TYPES = I18n.t(:"odp.application_types").to_h.freeze

  attribute :legislation_type, :string, default: "existing"

  enum :status, {inactive: "inactive", active: "active", retired: "retired"}

  belongs_to :legislation, optional: true
  has_many :planning_applications, dependent: :restrict_with_exception

  accepts_nested_attributes_for :legislation

  default_scope { preload(:legislation) }

  validates :name, :code, :suffix, presence: true
  validates :code, :suffix, uniqueness: true

  with_options allow_blank: true do
    validates :code, inclusion: {in: ODP_APPLICATION_TYPES.keys}
    validates :suffix, length: {within: 2..6}
    validates :suffix, format: {with: /\A[A-Z0-9]+\z/}
  end

  with_options on: :update do
    validate if: :code_changed? do
      errors.add(:code, :readonly, status:) unless inactive?
    end

    validate if: :suffix_changed? do
      errors.add(:suffix, :readonly, status:) unless inactive?
    end
  end

  with_options on: :legislation do
    validate if: :existing_legislation? do
      errors.add(:legislation_id, :blank) unless legislation&.persisted?
    end
  end

  with_options on: :determination_period do
    validates :determination_period_days, presence: true
    validates :determination_period_days, numericality: {only_integer: true}
    validates :determination_period_days, numericality: {greater_than_or_equal_to: 1}
    validates :determination_period_days, numericality: {less_than_or_equal_to: 99}
  end

  attribute :features, ApplicationTypeFeature.to_type

  with_options to: :features do
    delegate :planning_conditions?
    delegate :permitted_development_rights?
    delegate :site_visits?
    delegate :include_bank_holidays?
  end

  before_validation if: :code_changed? do
    self.name = \
      case code
      when /\Apa\./
        "prior_approval"
      when /\Aldc\./
        "lawfulness_certificate"
      when /\App\./
        "planning_permission"
      else
        "other"
      end
  end

  def existing_or_new_legislation
    (legislation_type == "new") ? legislation : Legislation.new
  end

  def description
    ODP_APPLICATION_TYPES[code]
  end

  def existing?
    code.include?(".existing")
  end

  def retrospective?
    code.include?(".retro")
  end

  def work_status
    if retrospective?
      "retrospective"
    elsif existing?
      "existing"
    else
      "proposed"
    end
  end

  def full_name
    name.humanize
  end

  def human_name
    I18n.t("application_types.#{name}")
  end

  def legislation_link
    fetch_legislation_translation("link")
  end

  def legislation_link_text
    fetch_legislation_translation("link_text")
  end

  def legislation_description
    fetch_legislation_translation("description")
  end

  def consultation?
    steps.include?("consultation")
  end

  def assessor_remarks
    assessment_details.excluding("past_applications", "check_publicity")
  end

  def irrelevant_tags(key)
    case key
    when "plans"
      Document::PLAN_TAGS - document_tags[key]
    when "evidence"
      Document::EVIDENCE_TAGS - document_tags[key]
    when "supporting_documents"
      (Document::SUPPORTING_DOCUMENT_TAGS - ["disabilityExemptionEvidence"]) - document_tags[key]
    when "other"
      []
    else
      raise ArgumentError, "Unexpected document tag type: #{key}"
    end
  end

  def type_name
    self.class.type_mapping[code]
  end

  class << self
    def by_name
      in_order_of(:name, NAME_ORDER).order(:name, :code)
    end

    def code_menu
      ODP_APPLICATION_TYPES.map(&:reverse)
    end

    def menu(scope = by_name)
      scope.active.order(code: :asc).map do |application_type|
        [application_type.description, application_type.id]
      end
    end
  end

  private

  def part_and_section
    "#{part}#{section}"
  end

  def fetch_legislation_translation(key)
    I18n.t("application_types.legislation.#{name}.#{part_and_section}.#{key}", default: false)
  end

  def existing_legislation?
    legislation_type == "existing"
  end

  def new_legislation?
    legislation_type == "new"
  end
end
