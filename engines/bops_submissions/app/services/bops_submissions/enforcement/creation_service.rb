# frozen_string_literal: true

module BopsSubmissions
  module Enforcement
    class CreationService
      def initialize(submission:, user:)
        @submission = submission
        @user = user
        @local_authority = submission.local_authority
        @data = submission.request_body.with_indifferent_access
      end

      def call!
        enforcement = ApplicationRecord.transaction do
          enforcement = build_enforcement
          enforcement.save!
          submission.create_case_record!(
            caseable: enforcement,
            local_authority: local_authority
          )
          enforcement
        end
        attach_documents!(enforcement) if submission.request_body["files"]
        enforcement
      end

      private

      attr_reader :submission, :data, :local_authority, :user

      def data_params
        @data_params ||= data.fetch(:data)
      end

      def build_enforcement
        local_authority.enforcements.new(enforcement_params)
      end

      def enforcement_params
        {}.tap do |enforcement_params|
          enforcement_params.merge!(parsed_data)
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

      def attach_documents!(enforcement)
        DocumentsService.new(case_record: enforcement.case_record, user:, files: submission.request_body["files"]).call!
      end
    end
  end
end
