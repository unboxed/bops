# frozen_string_literal: true

module Api
  module V1
    class ApplicationController < ApplicationController
      # Make ActiveStorage aware of the current host (used in url helpers)
      include ActiveStorage::SetCurrent

      before_action :authenticate, :set_default_format
      protect_from_forgery with: :null_session

      rescue_from ActionController::ParameterMissing do |e|
        render json: {error: e.message}, status: :bad_request
      end

      def set_default_format
        request.format = :json
      end

      def json_request?
        request.format.json?
      end

      def set_cors_headers
        response.set_header("Access-Control-Allow-Origin", "*")
        response.set_header("Access-Control-Allow-Methods", "*")
        response.set_header(
          "Access-Control-Allow-Headers",
          "Origin, X-Requested-With, Content-Type, Accept"
        )
        response.charset = "utf-8"
      end

      def check_token_and_set_application
        planning_applications_scope = current_local_authority.planning_applications
        reference = params[:planning_application_id]
        @planning_application =
          if reference.match?(/[a-z]/i)
            planning_applications_scope.find_by(reference:)
          else
            planning_applications_scope.find_by(id: Integer(reference))
          end

        if @planning_application
          if params[:change_access_id] == @planning_application.change_access_id
            @planning_application
          else
            render json: {message: "Change access id is invalid"}, status: :unauthorized
          end
        else
          render json: {message: "Unable to find planning application with id: #{params[:planning_application_id]}"},
            status: :not_found
        end
      end

      private

      def authenticate
        api_user = authenticate_or_request_with_http_token do |token, _options|
          current_local_authority.api_users.find_by(token:)
        end

        Current.api_user = api_user
      end

      def current_api_user
        @current_api_user ||= authenticate
      end

      def planning_application
        scope = current_local_authority.planning_applications
        param = if params.key? :reference
          params[:reference]
        elsif params.key? :planning_application_id
          params[:planning_application_id]
        else
          params[:id]
        end

        if param.match?(/[a-z]/i)
          scope.find_by(reference: param)
        else
          begin
            scope.find_by(id: Integer(param))
          rescue ArgumentError
            nil
          end
        end
      end

      protected

      def request_http_token_authentication(realm = "Application", _message = nil)
        headers["WWW-Authenticate"] = %(Token realm="#{realm.delete('"')}")
        render json: {error: "HTTP Token: Access denied."}, status: :unauthorized
      end
    end
  end
end
