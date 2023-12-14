# frozen_string_literal: true

module BopsApi
  module Errors
    class BaseError < ::StandardError; end
    class FileDownloaderNotConfiguredError < BaseError; end
    class InvalidRequestError < BaseError; end
    class InvalidSchemaError < BaseError; end
    class NotPermittedError < BaseError; end
    class SchemaNotFoundError < BaseError; end
  end
end
