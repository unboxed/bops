# frozen_string_literal: true

module BopsApi
  module ErrorHandler
    extend ActiveSupport::Concern

    EXCEPTIONS = {
      "ActiveRecord::RecordInvalid" => {status: 400, message: "Record Invalid"},
      "BopsApi::Errors::InvalidSchemaError" => {status: 400, message: "Bad Request"},
      "BopsApi::Errors::NotPermittedError" => {status: 403, message: "Forbidden"},
      "ActiveRecord::RecordNotFound" => {status: 404, message: "Cannot find record"},
      "StandardError" => {status: 500, message: "Internal Server Error"}
    }.freeze

    included do
      rescue_from StandardError do |exception|
        handle_error(exception, EXCEPTIONS[exception.class.name] || EXCEPTIONS["StandardError"])
      end
    end

    private

    def handle_error(exception, context)
      Appsignal.send_error(exception) do |transaction|
        transaction.params = {params: params.to_unsafe_hash}
      end

      render json: {error: build_error_response(context, exception)}, status: context[:status]
    end

    def build_error_response(context, exception)
      {
        code: context[:status],
        message: context[:message],
        detail: exception.message
      }
    end
  end
end
