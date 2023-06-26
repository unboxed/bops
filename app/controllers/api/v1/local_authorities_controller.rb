# frozen_string_literal: true

module Api
  module V1
    class LocalAuthoritiesController < Api::V1::ApplicationController
      before_action :set_cors_headers, if: :json_request?

      skip_before_action :authenticate

      def show
        @local_authority = LocalAuthority.find_by(subdomain: params[:subdomain])

        if @local_authority
          respond_to(:json)
        else
          send_not_found_response
        end
      end

      def send_not_found_response
        render json: { message: "Unable to find record" },
               status: :not_found
      end
    end
  end
end
