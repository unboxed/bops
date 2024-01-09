# frozen_string_literal: true

class ValidationRequestUpdateService
  class UpdateError < StandardError; end

  def initialize(validation_request:, params:)
    @validation_request = validation_request
    @params = params
    @planning_application = validation_request.planning_application
  end

  def call!
    ActiveRecord::Base.transaction do
      @validation_request.update!(validation_request_params)
      @validation_request.close!
      @validation_request.create_api_audit!
      @planning_application.send_update_notification_to_assessor

      if @validation_request.approved?
        @planning_application.update(valid_ownership_certificate: true)
        OwnershipCertificateCreationService.new(
          params: ownership_certificate_params[:params], planning_application: @planning_application
        ).call
      end
    end
  rescue => exception
    raise UpdateError, (exception.message || "Unable to update request. Please ensure response is present")
  end

  private

  def ownership_certificate_params
    @params.require(:data).permit(
      params: [:certificate_type, land_owners: %i[name address_1 address_2 town city postcode notice_given notice_given_at]]
    )
  end

  def validation_request_params
    @params.require(:data).permit(:approved, :rejection_reason)
  end
end
