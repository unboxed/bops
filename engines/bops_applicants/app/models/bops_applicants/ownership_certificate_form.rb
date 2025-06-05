# frozen_string_literal: true

module BopsApplicants
  class OwnershipCertificateForm
    class LandOwner
      include ActiveModel::API
      include ActiveModel::Attributes
      include ActiveRecord::AttributeAssignment

      attribute :name, :string
      attribute :address_1, :string
      attribute :address_2, :string
      attribute :town, :string
      attribute :country, :string
      attribute :postcode, :string
      attribute :notice_given_at, :date

      validates :name, presence: true
      validates :address_1, presence: true
      validates :town, presence: true
      validates :postcode, presence: true

      class << self
        def model_name
          @_model_name ||= ActiveModel::Name.new(self, nil, "LandOwner")
        end
      end

      def persisted?
        false
      end
    end

    include ActiveModel::API
    include ActiveModel::Attributes

    STAGES = %w[certificate_type new_owner owners].freeze
    OWNER_PARAMS = %i[name address_1 address_2 town country postcode notice_given_at].freeze
    CERTIFICATE_ATTRS = %i[know_owners number_of_owners certificate_type notification_of_owners].freeze
    CERTIFICATE_PARAMS = (CERTIFICATE_ATTRS + [land_owners: OWNER_PARAMS]).freeze

    PERMITTED_PARAMS = [
      :stage, :next_stage,
      ownership_certificate: CERTIFICATE_PARAMS,
      land_owner: OWNER_PARAMS
    ].freeze

    attribute :know_owners, :string
    attribute :number_of_owners, :string
    attribute :certificate_type, :string
    attribute :notification_of_owners, :string
    attribute :land_owners, array: true, default: -> { [] }

    validates :know_owners, presence: true, inclusion: {in: %w[yes no]}
    validates :certificate_type, presence: true, inclusion: {in: %w[B C D]}
    validates :notification_of_owners, presence: true, inclusion: {in: %w[yes no some]}

    with_options if: -> { know_owners == "yes" } do
      validates :number_of_owners, presence: true
      validates :number_of_owners, numericality: {only_integer: true, greater_than: 0}
    end

    validate do
      unless land_owners.all?(&:valid?)
        errors.add(:land_owners, :invalid)
      end
    end

    class << self
      def model_name
        @_model_name ||= ActiveModel::Name.new(self, nil, "OwnershipCertificate")
      end
    end

    def initialize(planning_application, validation_request, params)
      @planning_application = planning_application
      @validation_request = validation_request
      @params = params.permit(PERMITTED_PARAMS)

      super(ownership_certificate_params)
    end

    def failed?
      !!@failed
    end

    def land_owner
      @land_owner ||= LandOwner.new
    end

    def land_owners=(values)
      super(values.compact_blank.map { |index, attrs| LandOwner.new(attrs) })
    end

    def persisted?
      false
    end

    def save
      if adding_land_owner?
        land_owner.assign_attributes(land_owner_params)

        unless land_owner.valid?
          return false
        end

        land_owners << land_owner

        @stage = "owners" and return false
      end

      unless valid?(stage.to_sym)
        return false
      end

      if done?
        update_ownership_certificate
      else
        @stage = next_stage and return false
      end
    end

    def stage
      @stage ||= stage_param.in?(STAGES) ? stage_param : STAGES.first
    end

    def to_partial_path
      "bops_applicants/ownership_certificates/#{stage}"
    end

    private

    attr_reader :params, :planning_application, :validation_request

    def adding_land_owner?
      stage == "new_owner" && next_stage_param == "add_owner"
    end

    def done?
      stage == STAGES.last && next_stage_param == "send"
    end

    def land_owner_params
      params.fetch(:land_owner, {})
    end

    def next_stage
      STAGES.include?(next_stage_param) ? next_stage_param : stage
    end

    def next_stage_param
      params.fetch(:next_stage, stage)
    end

    def ownership_certificate_params
      params.fetch(:ownership_certificate, {})
    end

    def stage_index
      STAGES.index(stage)
    end

    def stage_param
      params.fetch(:stage, STAGES.first)
    end

    def transaction(&)
      ActiveRecord::Base.transaction(&)
    end

    def update_ownership_certificate
      transaction do
        ownership_certificate = planning_application.ownership_certificate

        if ownership_certificate.present?
          validation_request.update!(
            ownership_certificate_submitted: true,
            old_ownership_certificate: ownership_certificate.serialize
          )
        else
          validation_request.update!(ownership_certificate_submitted: true)
        end

        planning_application.create_ownership_certificate! do |c|
          c.certificate_type = certificate_type

          land_owners.each do |owner|
            c.land_owners.new do |o|
              o.assign_attributes(owner.attributes)
            end
          end
        end
      end

      true
    rescue
      @failed = true and return false
    end
  end
end
