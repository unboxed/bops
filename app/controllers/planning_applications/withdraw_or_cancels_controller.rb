# frozen_string_literal: true

module PlanningApplications
  class WithdrawOrCancelsController < AuthenticationController
    before_action :set_planning_application
    before_action :planning_application_status?, only: :update

    rescue_from PlanningApplication::WithdrawOrCancelError do |exception|
      redirect_failed_withdraw_or_cancel(exception)
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        @planning_application.withdraw_or_cancel!(
          planning_application_status, withdrawn_or_cancellation_comment, document_params
        )

        format.html { redirect_to @planning_application, notice: t(".#{planning_application_status}") }
      end
    end

    private

    def planning_application_params
      params.require(:planning_application).permit(documents_attributes: %i[file redacted])
    end

    def document_params
      planning_application_params if planning_application_params.dig(:documents_attributes, "0", "file")
    end

    def planning_application_status
      params[:planning_application][:status]
    end

    def planning_application_status?
      return if planning_application_status.present?

      @planning_application.errors.add(:status, "Please select one of the below options")

      render :show
    end

    def withdrawn_or_cancellation_comment
      params[:planning_application][:closed_or_cancellation_comment]
    end

    def redirect_failed_withdraw_or_cancel(error)
      redirect_to planning_application_withdraw_or_cancel_path(@planning_application),
                  alert: "Error withdrawing or cancelling the application with message: #{error.message}."
    end
  end
end
