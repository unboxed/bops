# frozen_string_literal: true

module BopsSubmissions
  module V2
    class AuthenticatedController < ApplicationController
      before_action :authenticate_api_user!

      private

      def required_api_key_scope = "planning_application"

      def authenticate_api_user
        return nil unless current_local_authority

        if sqid_param?
          authenticate_with_hmac_signature
        else
          super
        end
      end

      def sqid_param?
        params[:sqid].present?
      end

      def authenticate_with_hmac_signature
        sqid = params[:sqid].to_s
        signature = request.authorization.to_s
        timestamp = request.headers["tq-timestamp"].to_s

        current_local_authority.api_users.authenticate_with_hmac(sqid, signature, timestamp)
      end
    end
  end
end
