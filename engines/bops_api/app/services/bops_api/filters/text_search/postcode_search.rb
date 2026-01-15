# frozen_string_literal: true

module BopsApi
  module Filters
    module TextSearch
      class PostcodeSearch < BaseSearch
        POSTCODE_REGEX = /^(GIR\s?0AA|[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2})$/i

        class << self
          def apply(scope, query)
            return scope.none unless postcode_query?(query)

            scope.where("LOWER(replace(postcode,' ','')) = ?", query.delete(" "))
          end

          private

          def postcode_query?(query)
            query.match?(POSTCODE_REGEX)
          end
        end
      end
    end
  end
end
