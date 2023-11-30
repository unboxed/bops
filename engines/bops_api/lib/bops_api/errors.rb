# frozen_string_literal: true

module BopsApi
  module Errors
    class BaseError < ::StandardError; end

    class InvalidSchemaError < BaseError; end

    class NotPermittedError < BaseError; end
  end
end
