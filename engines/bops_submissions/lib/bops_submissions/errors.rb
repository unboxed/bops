# frozen_string_literal: true

module BopsSubmissions
  module Errors
    class BaseError < ::StandardError; end
    class EntityRemovedError < BaseError; end
    class EntityNotFoundError < BaseError; end
    class InvalidRequestError < BaseError; end
    class NotPermittedError < BaseError; end
  end
end
