# frozen_string_literal: true

module BopsApplicants
  class RedLineBoundaryChangeValidationRequestsController < ValidationRequestsController
    private

    def validation_request_params
      params.require(:validation_request).permit(:approved, :rejection_reason)
    end

    def update_validation_request
      transaction do
        @validation_request.update!(validation_request_params)
        @validation_request.close!
        @validation_request.create_api_audit!

        if @validation_request.approved?
          @validation_request.update_planning_application!
        end

        @planning_application.send_update_notification_to_assessor
      end

      true
    rescue
      false
    end
  end
end
