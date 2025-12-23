# frozen_string_literal: true

module BopsSubmissions
  module Application
    class OdpCreationService
      def initialize(submission:, user:, email_sending_permitted: false)
        @submission = submission
        @local_authority = submission.local_authority
        @user = user
        @params = submission.request_body.with_indifferent_access
        @email_sending_permitted = email_sending_permitted
      end

      def call!
        save!(build_planning_application)
      end

      private

      attr_reader :submission, :local_authority, :user, :params, :email_sending_permitted

      def data_params
        @data_params ||= params.fetch(:data)
      end

      def files
        @files ||= params.fetch(:files)
      end

      def build_planning_application
        case_record = submission.case_record || local_authority.case_records.new(submission:)

        local_authority.planning_applications.new(planning_application_params).tap do |pa|
          pa.api_user_id = user.id
          pa.case_record = case_record
        end
      end

      def planning_application_params
        {}.tap do |pa_params|
          pa_params.merge!(parsed_data)
          pa_params.merge!(other_params)
          pa_params.merge!(planx_planning_data_attributes: submission_parser.parse)
        end
      end

      def parsed_data
        parsers.each_with_object({}) do |(parser, data), hash|
          hash.merge!(parser.new(data, local_authority:).parse)
        end
      end

      def parsers
        {
          BopsApi::Application::Parsers::ApplicantParser => data_params[:applicant],
          BopsApi::Application::Parsers::AgentParser => data_params.dig(:applicant, :agent),
          BopsApi::Application::Parsers::FeeParser => data_params.dig(:application, :fee),
          BopsApi::Application::Parsers::AddressParser => data_params.dig(:property, :address),
          BopsApi::Application::Parsers::ApplicationTypeParser => data_params.dig(:application, :type),
          BopsApi::Application::Parsers::PreAssessmentParser => params[:preAssessment],
          BopsApi::Application::Parsers::ProposalParser => data_params[:proposal],
          BopsApi::Application::Parsers::ProposalDetailsParser => params[:responses]
        }
      end

      def submission_parser
        BopsApi::Application::Parsers::SubmissionParser.new(params, local_authority:)
      end

      def other_params
        {
          user_role: data_params[:user_role],
          from_production: from_bops_production?
        }
      end

      def save!(planning_application)
        PlanningApplication.transaction do
          if planning_application.save!
            BopsApi::PlanningApplicationDependencyJob.perform_later(
              planning_application:,
              user:,
              files:,
              params:,
              email_sending_permitted:
            )
          end
        end

        BopsApi::CreateNeighbourBoundaryGeojsonJob.perform_later(planning_application) if planning_application.consultation
        BopsApi::PostApplicationToStagingJob.perform_later(local_authority, planning_application) if Bops.env.production?

        planning_application
      end

      def from_bops_production?
        params.dig("metadata", "source") == "BOPS production"
      end
    end
  end
end
