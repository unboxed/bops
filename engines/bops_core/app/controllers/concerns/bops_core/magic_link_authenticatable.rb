# frozen_string_literal: true

module BopsCore
  module MagicLinkAuthenticatable
    extend ActiveSupport::Concern

    included do
      rescue_from ActionController::ParameterMissing do |exception|
        render plain: "Not Found", status: :not_found
      end
    end

    def authenticate_with_sgid!
      resource = sgid_authentication_service.locate_resource

      handle_expired_or_invalid_sgid if resource.nil?
    end

    private

    def sgid_authentication_service
      @sgid_authentication_service ||= SgidAuthenticationService.new(sgid)
    end

    def sgid
      params.require(:sgid)
    end

    def handle_expired_or_invalid_sgid
      if sgid_authentication_service.expired_resource
        render plain: "Magic link expired", status: :unprocessable_entity
      else
        render plain: "Forbidden", status: :forbidden
      end
    end
  end
end
