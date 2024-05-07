# frozen_string_literal: true

module BopsApi
  module Errors
    class BaseError < ::StandardError; end
    class FileDownloaderNotConfiguredError < BaseError; end
    class EntityFetchFailedError < BaseError; end
    class InvalidEntityResponseError < EntityFetchFailedError; end
    class EntityRemovedError < BaseError; end
    class EntityNotFoundError < BaseError; end
    class InvalidRequestError < BaseError; end
    class InvalidSchemaError < BaseError; end
    class NotPermittedError < BaseError; end
    class SchemaNotFoundError < BaseError; end
  end
end
