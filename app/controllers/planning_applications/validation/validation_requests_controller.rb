# frozen_string_literal: true

module PlanningApplications
  module Validation
    class ValidationRequestsController < AuthenticationController
      include PlanningApplicationAssessable

      rescue_from Notifications::Client::NotFoundError, with: :validation_notice_request_error
      rescue_from Notifications::Client::ServerError, with: :validation_notice_request_error
      rescue_from Notifications::Client::RequestError, with: :validation_notice_request_error
      rescue_from Notifications::Client::ClientError, with: :validation_notice_request_error
      rescue_from Notifications::Client::BadRequestError, with: :validation_notice_request_error
      rescue_from ValidationRequest::ValidationRequestNotCreatableError, with: :redirect_failed_create_request_error

      before_action :set_planning_application
      before_action :set_validation_request, only: %i[show edit update destroy cancel_confirmation cancel]
      before_action :set_document
      before_action :set_type, only: %i[new]
      before_action :ensure_planning_application_is_validated, only: :post_validation_requests
      before_action :ensure_planning_application_not_validated, only: %i[new create edit update]
      before_action :ensure_planning_application_not_invalidated, only: :edit
      before_action :ensure_planning_application_is_not_closed_or_cancelled, only: %i[new create]

      def index
        validation_requests = @planning_application.validation_requests.where(post_validation: false)
        @cancelled_validation_requests = validation_requests.cancelled
        @active_validation_requests = validation_requests.active

        respond_to do |format|
          format.html
        end
      end

      def new
        @validation_request = @planning_application.validation_requests.new(type: @type.camelize)
      end

      def show
        respond_to do |format|
          format.html
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        if @validation_request.update(validation_request_params.except(:return_to))
          redirect_to(
            create_request_redirect_url,
            notice: t(".#{@validation_request.type.underscore}.success")
          )
        else
          if @validation_request.type == "ReplacementDocumentValidationRequest"
            @document = @validation_request.old_document
          end
          render :edit, type: @validation_request.type.underscore
        end
      end

      def destroy
        @validation_request.destroy!

        respond_to do |format|
          if @validation_request.destroyed?
            format.html do
              redirect_to planning_application_validation_tasks_path(@planning_application),
                notice: t(".#{@validation_request.type.underscore}.success")
            end
          else
            format.html do
              redirect_to planning_application_validation_tasks_path(@planning_application),
                alert: t(".failure")
            end
          end
        end
      end

      def create
        @validation_request =
          ValidationRequest.new(
            validation_request_params.except(:return_to).merge!({planning_application_id: @planning_application.id})
          )
        @validation_request.user = current_user

        if @validation_request.save
          redirect_to(
            create_request_redirect_url,
            notice: t(".#{@validation_request.type.underscore}.success")
          )
        else
          if @validation_request.type == "ReplacementDocumentValidationRequest"
            @document = @validation_request.old_document
          end
          set_type
          render :new
        end
      end

      def cancel_confirmation
        respond_to do |format|
          format.html
        end
      end

      def cancel
        respond_to do |format|
          if @validation_request.may_cancel?
            @validation_request.assign_attributes(cancel_validation_request_params)
            @validation_request.cancel_request!

            @validation_request.send_cancelled_validation_request_mail unless @planning_application.not_started?

            format.html do
              redirect_to cancel_redirect_url,
                notice: t(".#{@validation_request.type.underscore}.success")
            end
          else
            format.html do
              @validation_request = @planning_application.validation_requests.find(params[:id].to_i)
              render :cancel_confirmation
            end
          end
        end
      end

      def post_validation_requests
        validation_requests = @planning_application.validation_requests.where(
          post_validation: true
        )

        @cancelled_validation_requests = validation_requests.cancelled
        @active_validation_requests = validation_requests.active

        respond_to do |format|
          format.html { render "index" }
        end
      end

      private

      def ensure_planning_application_not_validated
        if params[:type] == "fee_change" || params[:type] == "other_change"
          render plain: "forbidden", status: :forbidden and return unless @planning_application.can_validate?
        end
      end

      def ensure_planning_application_not_invalidated
        return if @planning_application.not_started?

        render plain: "forbidden", status: :forbidden
      end

      def validation_notice_request_error(exception)
        flash[:alert] = t("email_failure")

        Appsignal.send_error(exception)
        render "planning_applications/show"
      end

      def ensure_planning_application_is_not_closed_or_cancelled
        return unless @planning_application.closed_or_cancelled?

        render plain: "forbidden", status: :forbidden
      end

      def create_request_redirect_url
        if params.dig(:validation_request, :return_to)
          params.dig(:validation_request, :return_to) ||
            @planning_application
        elsif @planning_application.validated?
          @planning_application
        else
          planning_application_validation_tasks_path(@planning_application)
        end
      end

      def redirect_failed_create_request_error(error)
        redirect_to @planning_application, alert: error.message
      end

      def validation_request_params
        params.require(:validation_request)
          .permit(
            :new_geojson, :reason, :type, :suggestion,
            :document_request_type, :old_document_id, :proposed_description, :return_to
          )
      end

      def cancel_validation_request_params
        params.require(:validation_request).permit(:cancel_reason)
      end

      def set_document
        return unless params[:type] == "replacement_document" || @validation_request&.type == "ReplacementDocumentValidationRequest"

        if params[:document]
          @document = @planning_application.documents.find(params[:document].to_i)
        else
          @replacement_document_validation_request = @planning_application.validation_requests.find(params[:id].to_i)
          @document = @replacement_document_validation_request.old_document
        end
      end

      def cancel_redirect_url
        if params.dig(:validation_request, :return_to)
          params.dig(:validation_request, :return_to) ||
            @planning_application
        elsif @planning_application.validated?
          post_validation_requests_planning_application_validation_validation_requests_path(@planning_application)
        else
          planning_application_validation_validation_requests_path(@planning_application)
        end
      end

      def set_validation_request
        return if params[:id].blank?

        @validation_request = @planning_application.validation_requests.find(validation_request_id)
      end

      def validation_request_id
        Integer(params[:id].to_s)
      end

      def set_type
        @type = if params[:type]
          params.permit(:type)[:type] + "_validation_request"
        else
          params.require(:validation_request).permit(:type)[:type]
        end
      end
    end
  end
end
