# frozen_string_literal: true

module BopsApi
  module Application
    class CreationService
      class CreateError < StandardError; end

      def initialize(**options)
        raise CreateError, "Creating planning applications using this endpoint is not permitted in production" if Bops.env.production?

        options.each { |k, v| instance_variable_set("@#{k}", v) unless v.nil? }
      end

      def call
        planning_application = build_planning_application

        save!(planning_application)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, ActiveRecord::RecordNotUnique, ArgumentError, NoMethodError => e
        raise CreateError, e.message
      end

      private

      attr_reader :local_authority, :params, :api_user

      def data_params
        @data_params ||= params[:data]
      end

      def build_planning_application
        PlanningApplication.new(planning_application_params).tap do |pa|
          pa.api_user_id = api_user.id
          pa.local_authority_id = local_authority.id
        end
      end

      def planning_application_params
        {}.tap do |pa_params|
          pa_params.merge!(parsed_data)
          pa_params.merge!(other_params)
          pa_params.merge!(planx_planning_data_attributes: Parsers::SubmissionParser.new(params).parse)
        end
      end

      def parsed_data
        parsers.each_with_object({}) do |(parser, data), hash|
          hash.merge!(parser.new(data).parse)
        end
      end

      def parsers
        {
          "ApplicantParser" => data_params[:applicant],
          "AgentParser" => data_params[:applicant][:agent],
          "FeeParser" => data_params[:application][:fee],
          "AddressParser" => data_params[:property][:address],
          "ApplicationTypeParser" => data_params[:application][:type],
          "PreAssessmentParser" => params[:preAssessment],
          "ProposalParser" => data_params[:proposal],
          "ProposalDetailsParser" => params[:responses]
        }.transform_keys { |key| Parsers.const_get(key) }
      end

      def other_params
        {
          user_role: data_params[:user_role],
          from_production: params[:from_production].present?
        }
      end

      def save!(planning_application)
        PlanningApplication.transaction do
          if planning_application.save!
            planning_application.mark_pending!
            AnonymisationService.new(planning_application:).call! if planning_application.from_production?

            # TODO: create constraints
            # TODO: create documents
            # TODO: create immunity details

            planning_application.send_receipt_notice_mail unless skip_email?(planning_application)
          end
        end

        planning_application
      end

      def skip_email?(planning_application)
        params[:send_email] == "false" || planning_application.pending?
      end
    end
  end
end
