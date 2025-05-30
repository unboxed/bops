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

      def build_planning_application
        PlanningApplication.new(planning_application_params).tap do |pa|
          pa.local_authority_id = local_authority.id
        end
      end

      def planning_application_params
        {}.tap do |pa_params|
          pa_params.merge!(parsed_data)
          pa_params.merge!(application_type_params)
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
          "ProposalParser" => params,
          "ProposalDetailsParser" => params["applicationData"]
        }.transform_keys { |key| Parsers.const_get(key) }
      end

      def application_type_params
        {
          application_type: local_authority.application_types.find_or_create_by!(code: "pp.full.householder")
          # Planning portal are not currently sending application type, for now we are saving all as a full hosueholder so we are able to pass validation on the.
        }
      end

      def save!(planning_application)
        PlanningApplication.transaction do
          if planning_application.save!
            puts "Planning application saved"
            # Call background jobs
          end
        end

        planning_application
      end
    end
  end
end
