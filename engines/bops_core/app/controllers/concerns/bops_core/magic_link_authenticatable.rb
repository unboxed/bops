# frozen_string_literal: true

module BopsCore
  module MagicLinkAuthenticatable
    extend ActiveSupport::Concern

    included do
      rescue_from ActionController::ParameterMissing do |exception|
        render_not_found
      end
    end

    def authenticate_with_sgid!
      @resource = sgid_authentication_service.locate_resource

      handle_expired_or_invalid_sgid if @resource.nil?
    end

    private

    def sgid_authentication_service
      @sgid_authentication_service ||= SgidAuthenticationService.new(sgid)
    end

    def sgid
      params.require(:sgid)
    end

    def handle_expired_or_invalid_sgid
      if (resource = sgid_authentication_service.expired_resource)
        @resend_link = resource.sgid
        render_expired
      else
        render_not_found
      end
    end

    def render_not_found
      render plain: "Not found", status: :not_found
    end

    def render_expired
      raise NotImplementedError, "Subclasses must implement a render_expired method"
    end
  end
end
