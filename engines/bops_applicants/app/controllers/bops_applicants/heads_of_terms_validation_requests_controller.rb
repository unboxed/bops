# frozen_string_literal: true

module BopsApplicants
  class HeadsOfTermsValidationRequestsController < ValidationRequestsController
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
