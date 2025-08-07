# frozen_string_literal: true

module BopsSubmissions
  module Application
    class CreationService
      def initialize(submission:)
        @submission = submission
        @local_authority = submission.local_authority
        @data = submission.json_file&.with_indifferent_access
      end

      def call!
        verify_application_json!
        create_planning_application!
        attach_documents!
        @planning_application.mark_accepted!
      end

      private

      attr_reader :submission, :data, :local_authority

      def verify_application_json!
        unless data.is_a?(Hash) && data.present?
          raise ArgumentError, "Submission: #{submission.id} has no valid application JSON"
        end
      end

      def create_planning_application!
        @planning_application = build_planning_application
        @planning_application.save!
      end

      def build_planning_application
        local_authority.planning_applications.new(planning_application_params)
      end

      def planning_application_params
        {}.tap do |pa_params|
          pa_params.merge!(parsed_data)
          pa_params.merge!(application_type_params)
        end
      end

      def parsed_data
        parsers.each_with_object({}) do |(parser, section_data), hash|
          hash.merge!(parser.new(section_data, source: submission.source, local_authority:).parse)
        end
      end

      def parsers
        {
          "ApplicantParser" => data.dig("applicationData", "applicant"),
          "AgentParser" => data.dig("applicationData", "agent"),
          "AddressParser" => data.dig("applicationData", "siteLocation"),
          "FeeParser" => data["feeCalculationSummary"],
          "ProposalParser" => data
        }.transform_keys { |key| Parsers.const_get(key) }
      end

      def application_type_params
        # Planning portal are not currently sending application type. For now, we save all as full householder to pass validation.
        {application_type: local_authority.application_types.find_or_create_by!(code: "pp.full.householder")}
      end

      def attach_documents!
        submission.documents.find_each do |document|
          document.update!(planning_application: @planning_application)
        end
      end
    end
  end
end
