# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class BaseParser
      attr_reader :params

      def initialize(params)
        @params = params
      end
    end
  end
end
