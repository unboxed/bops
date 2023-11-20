# frozen_string_literal: true

module BopsApi
  class ApplicationController < ActionController::API
    include ActionController::MimeResponds

    before_action :set_local_authority

    private

    def set_local_authority
      @local_authority = LocalAuthority.find_by!(subdomain: request.subdomain)
    end
  end
end
