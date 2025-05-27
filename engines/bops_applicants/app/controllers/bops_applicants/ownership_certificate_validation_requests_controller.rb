# frozen_string_literal: true

module BopsApplicants
  class OwnershipCertificateValidationRequestsController < ValidationRequestsController
    def update
      respond_to do |format|
        if update_validation_request
          if @validation_request.approved?
            format.html { redirect_to new_validation_request_ownership_certificate_path(@validation_request, access_control_params) }
          else
            format.html { redirect_to validation_requests_url(access_control_params), notice: t(".success") }
          end
        else
          format.html { render :edit, alert: t(".failure_html", feedback_email: current_local_authority.feedback_email) }
        end
      end
    end

    private

    def validation_request_params
      params.require(:validation_request).permit(:approved, :rejection_reason)
    end

    def update_validation_request
      transaction do
        @validation_request.update!(validation_request_params)
        @validation_request.close!
        @validation_request.create_api_audit!

        @planning_application.send_update_notification_to_assessor
      end

      true
    rescue
      false
    end
  end
end
