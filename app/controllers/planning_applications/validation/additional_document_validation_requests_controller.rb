# frozen_string_literal: true

module PlanningApplications
  module Validation
    class AdditionalDocumentValidationRequestsController < ValidationRequestsController
      include ValidationRequests

      before_action :set_additional_document_validation_request, only: %i[edit update]
      before_action :ensure_planning_application_is_not_closed_or_cancelled, only: %i[new create]
      before_action :ensure_planning_application_not_validated, only: %i[edit update]
      before_action :ensure_planning_application_not_invalidated, only: :edit

      def new
        @additional_document_validation_request = @planning_application.additional_document_validation_requests.new

        respond_to do |format|
          format.html
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def create
        @additional_document_validation_request =
          @planning_application.additional_document_validation_requests.new(additional_document_validation_request_params)
        @additional_document_validation_request.user = current_user

        respond_to do |format|
          if @additional_document_validation_request.save
            format.html do
              redirect_to(
                create_request_redirect_url,
                notice: I18n.t("planning_applications.validation.additional_document_validation_requests.create.success")
              )
            end
          else
            format.html { render :new }
          end
        end
      end

      def update
        respond_to do |format|
          if @additional_document_validation_request.update(additional_document_validation_request_params)
            format.html do
              redirect_to planning_application_validation_tasks_path(@planning_application), notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def create_request_redirect_url
        params.dig(:additional_document_validation_request, :return_to) || super
      end

      def additional_document_validation_request_params
        params.require(:additional_document_validation_request).permit(:document_request_type, :document_request_reason)
      end

      def set_additional_document_validation_request
        @additional_document_validation_request =
          @planning_application.additional_document_validation_requests.find(params[:id])
      end

      def cancel_redirect_url
        if @planning_application.validated?
          @planning_application
        else
          planning_application_validation_validation_requests_path(@planning_application)
        end
      end
    end
  end
end