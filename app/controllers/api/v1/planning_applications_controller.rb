# frozen_string_literal: true

module Api
  module V1
    class PlanningApplicationsController < Api::V1::ApplicationController
      before_action :set_cors_headers, only: %i[index show create], if: :json_request?

      skip_before_action :authenticate, only: %i[index show decision_notice]
      skip_before_action :set_default_format, only: %i[decision_notice]

      def index
        @planning_applications = current_local_authority.planning_applications.all

        respond_to(:json)
      end

      def show
        @planning_application = current_local_authority.planning_applications.where(id: params[:id]).first
        if @planning_application
          respond_to(:json)
        else
          send_not_found_response
        end
      end

      def decision_notice
        @planning_application = current_local_authority.planning_applications.where(id: params[:id]).first
        @blank_layout = true
      end

      def create
        @planning_application = PlanningApplication.new(
          planning_application_params.merge!(
            local_authority_id: @current_local_authority.id,
            boundary_geojson: (params[:boundary_geojson].to_json if params[:boundary_geojson].present?),
            proposal_details: (params[:proposal_details].to_json if params[:proposal_details].present?),
            constraints: constraints_array_from_param(params[:constraints]),
            planx_data: (params[:planx_debug_data].to_json if params[:planx_debug_data].present?),
            api_user: current_api_user,
            audit_log: params.to_json
          )
        )

        @planning_application.assign_attributes(site_params) if site_params.present?
        @planning_application.assign_attributes(result_params) if result_params.present?

        begin
          PlanningApplication.transaction do
            if @planning_application.valid? && @planning_application.save!
              upload_documents(params[:files])

              send_success_response
              if @planning_application.agent_email.present? || @planning_application.applicant_email.present?
                receipt_notice_mail
              end
            else
              send_failed_response
            end
          end
        rescue Errors::WrongFileTypeError => e
          send_failed_response(e.message)
        end
      end

      def upload_documents(document_params)
        document_params&.each do |param|
          file = URI.parse(param[:filename]).open

          unless Document::PERMITTED_CONTENT_TYPES.include? file.content_type
            raise Errors::WrongFileTypeError.new(nil, param[:filename])
          end

          @planning_application.documents.create!(tags: Array(param[:tags]),
                                                  applicant_description: param[:applicant_description]) do |document|
            document.file.attach(io: file, filename: new_filename(param[:filename]).to_s)
          end
        end
      end

      def new_filename(name)
        name.split("/")[-1]
      end

      def send_success_response
        render json: { id: @planning_application.reference.to_s,
                       message: "Application created" }, status: :ok
      end

      def send_failed_response(message = nil)
        render json: { message: message || "Unable to create application" },
               status: :bad_request
      end

      def send_not_found_response
        render json: { message: "Unable to find record" },
               status: :not_found
      end

      private

      def planning_application_params
        permitted_keys = %i[application_type
                            description
                            applicant_first_name
                            applicant_last_name
                            applicant_phone
                            applicant_email
                            agent_first_name
                            agent_last_name
                            agent_phone
                            agent_email
                            proposal_details
                            files
                            payment_reference
                            payment_amount
                            work_status
                            planx_debug_data]
        params.permit permitted_keys
      end

      def constraints_array_from_param(constraints_params)
        if constraints_params.present?
          constraints_params.to_unsafe_hash.collect do |key, value|
            key if value
          end.compact
        else
          []
        end
      end

      def site_params
        if params[:site]
          { uprn: params[:site][:uprn],
            address_1: params[:site][:address_1],
            address_2: params[:site][:address_2],
            town: params[:site][:town],
            postcode: params[:site][:postcode],
            latitude: params[:site][:latitude],
            longitude: params[:site][:longitude] }
        end
      end

      def result_params
        if params[:result]
          { result_flag: params[:result][:flag],
            result_heading: params[:result][:heading],
            result_description: params[:result][:description],
            result_override: params[:result][:override] }
        end
      end

      def receipt_notice_mail
        @planning_application.applicant_and_agent_email.each do |user|
          PlanningApplicationMailer.receipt_notice_mail(
            @planning_application,
            request.host,
            user
          ).deliver_now
        end
      end
    end
  end
end
