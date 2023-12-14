# frozen_string_literal: true

module BopsApi
  class ApplicationController < ActionController::Base
    include ErrorHandler
    include SchemaValidation

    protect_from_forgery with: :null_session, prepend: true
    wrap_parameters false

    before_action :set_local_authority

    private

    def set_local_authority
      @local_authority = LocalAuthority.find_by!(subdomain: request.subdomain)
    end
  end
end
