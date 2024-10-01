# frozen_string_literal: true

module BopsApi
  module ErrorHandler
    extend ActiveSupport::Concern

    EXCEPTIONS = Hash.new(:internal_server_error).merge(
      "ActionController::BadRequest" => :bad_request,
      "ActiveRecord::RecordNotFound" => :not_found,
      "ActiveRecord::RecordInvalid" => :unprocessable_entity,
      "ActiveRecord::RecordNotSaved" => :unprocessable_entity,
      "BopsApi::Errors::InvalidRequestError" => :bad_request,
      "BopsApi::Errors::NotPermittedError" => :forbidden
    ).freeze

    included do
      rescue_from StandardError do |exception|
        Appsignal.add_tags(appsignal_tags)

        Appsignal.send_error(exception) do |transaction|
          transaction.params = {params: params.to_unsafe_hash}
        end

        code = Rack::Utils.status_code(EXCEPTIONS[exception.class.name])
        message = Rack::Utils::HTTP_STATUS_CODES[code]

        error = {
          code: code,
          message: message,
          detail: exception.message
        }

        render json: {error: error}, status: code
      end

      private

      def appsignal_tags
        tags = {request_url: request.url}

        if @local_authority
          tags[:local_authority] = @local_authority.subdomain
        end

        if @current_user
          tags[:api_user] = @current_user.name
          tags[:api_user_id] = @current_user.id
        end

        tags
      end
    end
  end
end
