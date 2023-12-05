# frozen_string_literal: true

module BopsApi
  module Application
    class CreationService
      def initialize(local_authority: nil, user: nil, params: nil, planning_application: nil, send_email: false)
        raise_not_permitted_in_production_error if BopsApi.env.production?

        if planning_application
          initialize_from_planning_application(planning_application)
        else
          @local_authority = local_authority
          @user = user
          @params = params
          @send_email = send_email
        end
      end

      def call!
        save!(build_planning_application)
      end

      private

      attr_reader :local_authority, :params, :user

      def data_params
        @data_params ||= params.fetch(:data)
      end

      def files
        @files ||= params.fetch(:files)
      end

      def build_planning_application
        PlanningApplication.new(planning_application_params).tap do |pa|
          pa.api_user_id = user.id
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
            AnonymisationService.new(planning_application:).call! if planning_application.from_production?
            DocumentsService.new(planning_application:, user:, files:).call!

            # TODO: create constraints
            process_ownership_certificate_details(planning_application)
            process_immunity_details(planning_application) if possibly_immune?(planning_application)

            planning_application.send_receipt_notice_mail if send_email?(planning_application)
          end
        end

        planning_application
      end

      def send_email?(planning_application)
        @send_email && !planning_application.pending?
      end

      def initialize_from_planning_application(planning_application)
        params_v2 = planning_application.params_v2 || raise_not_permitted_to_clone_error

        @params = ActionController::Parameters.new(JSON.parse(params_v2))
        @local_authority = planning_application.local_authority
        @user = planning_application.api_user
        @send_email = false
      end

      def raise_not_permitted_in_production_error
        raise BopsApi::Errors::NotPermittedError, "Creating planning applications using this endpoint is not permitted in production"
      end

      def raise_not_permitted_to_clone_error
        raise BopsApi::Errors::NotPermittedError, "Planning application cannot be cloned without V2 params"
      end

      def process_ownership_certificate_details(planning_application)
        ownership_details = data_params[:applicant][:ownership]

        ActiveRecord::Base.transaction do
          ownership_certificate = OwnershipCertificate.create(planning_application:, certificate_type: ownership_details[:certificate])

          if ownership_details[:owners].present?
            ownership_details[:owners].each do |owner|
              LandOwner.create(
                ownership_certificate:,
                name: owner[:name],
                town: owner[:address][:town],
                address_1: owner[:address][:line1],
                address_2: owner[:address][:line2],
                county: owner[:address][:county],
                country: owner[:address][:country],
                postcode: owner[:address][:postcode],
                notice_given: owner[:noticeDate].present?,
                notice_given_at: owner[:noticeDate],
                notice_reason: owner[:noticeReason]
              )
            end
          end
        end
      end

      def possibly_immune?(planning_application)
        planning_application.immune_proposal_details.many?
      end

      def process_immunity_details(planning_application)
        ActiveRecord::Base.transaction do
          immunity_detail = ImmunityDetail.new(planning_application: planning_application)
          immunity_detail.end_date = planning_application
            .find_proposal_detail("When were the works completed?")
            .first.response_values.first
          immunity_detail.save!
        end

        Document::EVIDENCE_TAGS.each do |tag|
          next if planning_application.documents.with_tag(tag).empty?

          planning_application.documents.with_tag(tag).each do |doc|
            planning_application.immunity_detail.add_document(doc)
          end
        end

        planning_application.immunity_detail.evidence_groups.each do |eg|
          Document::EVIDENCE_QUESTIONS[eg.tag.to_sym].each do |question|
            case question
            when /show/
              eg.applicant_comment = planning_application.find_proposal_detail(question).first.response_values.first
            when /(start|issued)/
              eg.start_date = planning_application.find_proposal_detail(question).first.response_values.first
            when /run/
              eg.end_date = planning_application.find_proposal_detail(question).first.response_values.first
            end
            eg.save!
          end
        end
      rescue ActiveRecord::RecordInvalid, NoMethodError => e
        Appsignal.send_error(e)
      end
    end
  end
end
