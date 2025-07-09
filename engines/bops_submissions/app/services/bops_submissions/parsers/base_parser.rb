# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class BaseParser
      attr_reader :params, :source, :local_authority

      def initialize(params, source:, local_authority:)
        @params = params
        @source = source
        @local_authority = local_authority
      end
    end
  end
end
