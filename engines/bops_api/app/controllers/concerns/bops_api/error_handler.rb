# frozen_string_literal: true

module BopsApi
  module ErrorHandler
    extend ActiveSupport::Concern

    EXCEPTIONS = Hash.new(:internal_server_error).merge(
      "ActiveRecord::RecordNotFound" => :not_found,
      "ActiveRecord::RecordInvalid" => :unprocessable_entity,
      "ActiveRecord::RecordNotSaved" => :unprocessable_entity,
      "BopsApi::Errors::InvalidRequestError" => :bad_request,
      "BopsApi::Errors::NotPermittedError" => :forbidden
    ).freeze

    included do
      rescue_from StandardError do |exception|
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
    end
  end
end
