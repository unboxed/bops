# frozen_string_literal: true

class OwnershipCertificateCreationService
  class CreateError < StandardError; end

  def initialize(planning_application:, params:)
    @planning_application = planning_application
    @params = params
  end

  def call
    save_ownership_certificate!
  end

  private

  attr_reader :params, :planning_application

  def save_ownership_certificate!
    if planning_application.ownership_certificate.present?
      certificate = planning_application.ownership_certificate.update!(
        response_params
      )

      certificate
    else 
      certificate = planning_application.build_ownership_certificate(
        response_params
      )

      certificate.save!

      certificate
    end
  rescue ActiveRecord::RecordInvalid => e
    raise CreateError, e.message
  end

  def response_params
    params.permit(
      :certificate_type, land_owners_attributes: [:name, :address_1, :address_2, :town, :country, :postcode, :notice_given_at, :notice_given]
    )
  end
end
