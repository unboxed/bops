# frozen_string_literal: true

module BopsSubmissions
  module Enforcement
    class CreationService
      def initialize(submission:)
        @submission = submission
        @local_authority = submission.local_authority
        @data = submission.request_body.with_indifferent_access
      end

      def call!
        ApplicationRecord.transaction do
          enforcement = build_enforcement
          enforcement.save!

          submission.create_case_record!(
            caseable: enforcement,
            local_authority: local_authority
          )

          enforcement
        end
      end

      private

      attr_reader :submission, :data, :local_authority

      def data_params
        @data_params ||= data.fetch(:data)
      end

      def build_enforcement
        local_authority.enforcements.new(enforcement_params)
      end

      def enforcement_params
        {}.tap do |enforcement_params|
          enforcement_params.merge!(parsed_data)
          enforcement_params.merge!(application_type_params)
        end
      end

      def parsed_data
        parsers.each_with_object({}) do |(parser, section_data), hash|
          hash.merge!(parser.new(section_data, source: submission.source, local_authority:).parse)
        end
      end

      def parsers
        {
          "AddressParser" => data_params[:property][:address],
          "ProposalParser" => data_params[:report],
          "ProposalDetailsParser" => data[:responses]
        }.transform_keys { |key| Parsers.const_get(key) }
      end

      def application_type_params
        config = ApplicationType::Config.find_by!(code: "breach")
        {application_type: local_authority.application_types.find_or_create_by!(config_id: config.id, code: config.code, name: config.name, suffix: config.suffix)}
      end
    end
  end
end
