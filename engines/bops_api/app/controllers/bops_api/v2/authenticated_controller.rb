# frozen_string_literal: true

module BopsApi
  module V2
    class AuthenticatedController < ApplicationController
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate

      private

      def authenticate
        user = authenticate_with_http_token do |token, options|
          User.authenticate(token)
        end

        if user
          @current_user = user
        else
          json = {
            error: {
              code: 401,
              message: "Unauthorized"
            }
          }

          render json: json, status: :unauthorized
        end
      end
    end
  end
end
