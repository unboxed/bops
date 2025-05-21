# frozen_string_literal: true

module BopsSubmissions
  module Application
    class CreationService
      def initialize(local_authority: nil, params: nil)
        @local_authority = local_authority
        @params = params
      end

      def call!
        save!(build_planning_application)
      end

      private

      attr_reader :local_authority, :params

      def files
        @files ||= params.fetch(:files)
      end

      def build_planning_application
        PlanningApplication.new(planning_application_params).tap do |pa|
          pa.local_authority_id = local_authority.id
        end
      end

      def planning_application_params
        {}.tap do |pa_params|
          pa_params.merge!(parsed_data)
          pa_params.merge!(other_params)
          pa_params.merge!(planx_planning_data_attributes: Parsers::SubmissionParser.new(params, local_authority:).parse)
        end
      end

      def parsed_data
        parsers.each_with_object({}) do |(parser, data), hash|
          hash.merge!(parser.new(data, local_authority:).parse)
        end
      end

      def parsers
        {
          "ApplicantParser" => params["applicationData"]["applicant"],
          "AgentParser" => params["applicationData"]["agent"],
          "AddressParser" => params["applicationData"]["siteLocation"],
          "FeeParser" => params["feeCalculationSummary"],
          "ProposalParser" => [params["polyglon"], params["proposalDescription"]],
          "ProposalDetailsParser" => params["applicationData"]
        }.transform_keys { |key| Parsers.const_get(key) }
      end

      def save!(planning_application)
        PlanningApplication.transaction do
          if planning_application.save!
            # Call background jobs
          end
        end

        planning_application
      end
    end
  end
end
