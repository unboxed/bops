# frozen_string_literal: true

class ApplicationType < ApplicationRecord
  class Config < ApplicationRecord
    include BopsCore::AuditableModel
    include StoreModel::NestedAttributes

    self.audit_attributes = %w[code]

    NAME_ORDER = %w[prior_approval planning_permission lawfulness_certificate pre_application other].freeze
    ODP_APPLICATION_TYPES = I18n.t(:"odp.application_types").to_h.freeze
    CURRENT_APPLICATION_TYPES = I18n.t(:"odp.current_application_types").freeze

    attribute :legislation_type, :string, default: "existing"
    attribute :document_tags, ApplicationTypeDocumentTags.to_type
    attribute :features, ApplicationTypeFeature.to_type

    enum :category, {
      advertisment: "advertisment",
      certificate_of_lawfulness: "certificate-of-lawfulness",
      change_of_use: "change-of-use",
      conservation_area: "conservation-area",
      full: "full",
      hedgerows: "hedgerows",
      householder: "householder",
      listed_building: "listed-building",
      non_material_amendment: "non-material-amendment",
      outline: "outline",
      prior_approval: "prior-approval",
      reserved_matters: "reserved-matters",
      tree_works: "tree-works",
      other: "other"
    }, scopes: false, instance_methods: false, validate: {on: :category}

    enum :status, %i[inactive active retired].index_with(&:to_s)

    belongs_to :legislation, optional: true
    has_many :application_types, dependent: :restrict_with_exception

    with_options through: :application_types do
      has_many :local_authorities
      has_many :planning_applications, -> { kept }, dependent: :restrict_with_exception
    end

    accepts_nested_attributes_for :legislation, :document_tags

    scope :not_retired, -> { where.not(status: "retired") }
    default_scope { preload(:legislation) }

    validates :name, :code, :suffix, presence: true
    validates :code, :suffix, uniqueness: true
    validates :features, store_model: {merge_errors: true}

    with_options presence: {message: :blank_when_activating} do
      validates :category, :legislation, if: :activating?
      validates :reporting_types, if: -> { category? && activating? }
    end

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

    with_options on: :reporting do
      validates :reporting_types, presence: true
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

    with_options to: :features do
      delegate :appeals?
      delegate :assess_against_policies?
      delegate :cil?
      delegate :considerations?
      delegate :consultations_skip_bank_holidays?
      delegate :description_change_requires_validation?
      delegate :eia?
      delegate :informatives?
      delegate :legislative_requirements?
      delegate :ownership_details?
      delegate :permitted_development_rights?
      delegate :planning_conditions?
      delegate :site_visits?
    end

    with_options to: :legislation, prefix: true, allow_nil: true do
      delegate :title
      delegate :description
      delegate :link
    end

    with_options on: :decision do
      validates :decisions, presence: true
    end

    before_validation if: :code_changed? do
      self.name =
        case code
        when /\Apa\./
          "prior_approval"
        when /\Aldc\./
          "lawfulness_certificate"
        when /\App\./
          "planning_permission"
        when /\ApreApp(?:\z|\.)/
          "pre_application"
        else
          "other"
        end
    end

    before_validation if: :code_changed? do
      if code =~ /^pa.part(\d+).class(\w+)$/
        self.part = $1
        self.section = $2
      elsif code =~ /^pa.part(\d+)$/
        self.part = $1
      end
    end

    before_update unless: :assessment_details? do
      self.assessment_details =
        case name
        when "lawfulness_certificate"
          %w[summary_of_work site_description consultation_summary additional_evidence]
        when "prior_approval"
          %w[summary_of_work site_description additional_evidence neighbour_summary amenity check_publicity]
        when "planning_permission"
          %w[summary_of_work site_description additional_evidence consultation_summary neighbour_summary check_publicity]
        else
          %w[summary_of_work site_description additional_evidence consultation_summary neighbour_summary check_publicity]
        end
    end

    before_update unless: :consistency_checklist? do
      self.consistency_checklist =
        case name
        when "lawfulness_certificate"
          %w[description_matches_documents documents_consistent proposal_details_match_documents site_map_correct]
        when "prior_approval"
          %w[description_matches_documents documents_consistent proposal_details_match_documents proposal_measurements_match_documents site_map_correct]
        when "planning_permission"
          %w[description_matches_documents documents_consistent proposal_details_match_documents site_map_correct]
        else
          %w[description_matches_documents documents_consistent proposal_details_match_documents site_map_correct]
        end
    end

    before_validation on: :decision, unless: :configured? do
      self.configured = true
    end

    class << self
      def by_name
        in_order_of(:name, NAME_ORDER).order(:name, :code)
      end

      def code_menu
        existing_codes = not_retired.pluck(:code)

        ODP_APPLICATION_TYPES.each_with_object([]) do |item, memo|
          next memo if existing_codes.include?(item.first)
          next memo unless CURRENT_APPLICATION_TYPES.include?(item.first)

          memo << item.reverse
        end
      end

      def reporting_type_used?(codes)
        where(reporting_types.contains(normalize_codes(codes))).exists?
      end

      def outstanding
        CURRENT_APPLICATION_TYPES - not_retired.pluck(:code)
      end

      private

      def reporting_types
        arel_table[:reporting_types]
      end

      def normalize_codes(codes)
        Array.wrap(codes).compact_blank
      end
    end

    def model_name
      @_model_name ||= ActiveModel::Name.new(self, nil, "ApplicationType")
    end

    def activating?
      status_changed? && active?
    end

    def existing_or_new_legislation
      (legislation_type == "new") ? legislation : Legislation.new
    end

    def description
      ODP_APPLICATION_TYPES[code]
    end

    def deprecated?
      CURRENT_APPLICATION_TYPES.exclude?(code)
    end

    def existing?
      code.include?(".existing")
    end

    def prior_approval?
      code.start_with?("pa.")
    end

    def retrospective?
      code.include?(".retro")
    end

    def pre_application?
      code == "preApp"
    end

    def lawfulness_certificate?
      name == "lawfulness_certificate"
    end

    def planning_permission?
      name == "planning_permission"
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

    def consultation?
      steps.include?("consultation")
    end

    def consultation_steps
      return [] unless consultation?

      features.consultation_steps
    end

    Consultation::STEPS.each do |feature|
      define_method(:"#{feature}_consultation_feature?") do
        consultation_steps.include?(feature)
      end
    end

    def assessor_remarks
      assessment_details.excluding("check_publicity")
    end

    def type_name
      self.class.type_mapping[code]
    end

    def reporting_types=(values)
      super(Array.wrap(values).compact_blank)
    end

    def all_reporting_types
      @all_reporting_types ||= ReportingType.for_category(category)
    end

    def all_reporting_type_codes
      all_reporting_types.map(&:code)
    end

    def selected_reporting_types
      @selected_reporting_types || ReportingType.for_codes(reporting_types)
    end

    def selected_reporting_types?
      selected_reporting_types.present?
    end

    def decisions=(values)
      super(Array.wrap(values).compact_blank)
    end

    def all_decisions
      @all_decisions ||= Decision.for_category(category)
    end

    def all_decision_codes
      all_decisions.map(&:code)
    end

    private

    def existing_legislation?
      legislation_type == "existing"
    end

    def new_legislation?
      legislation_type == "new"
    end
  end
end
