# frozen_string_literal: true

module BopsApi
  module Filters
    class FilterChain
      class << self
        def apply(filters, scope, params)
          filters.reduce(scope) { |current_scope, filter| filter.call(current_scope, params) }
        end
      end
    end
  end
end
