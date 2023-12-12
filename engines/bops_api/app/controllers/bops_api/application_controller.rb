# frozen_string_literal: true

module BopsApi
  class ApplicationController < ActionController::API
    include ActionController::MimeResponds
    include ErrorHandler
    include SchemaValidation

    before_action :set_local_authority
    wrap_parameters false

    private

    def set_local_authority
      @local_authority = LocalAuthority.find_by!(subdomain: request.subdomain)
    end
  end
end
