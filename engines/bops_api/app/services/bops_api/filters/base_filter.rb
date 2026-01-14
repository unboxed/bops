# frozen_string_literal: true

module BopsApi
  module Filters
    class BaseFilter
      class << self
        def call(scope, params)
          return scope unless applicable?(params)

          apply(scope, params)
        end

        private

        def applicable?(params)
          raise NotImplementedError, "#{name} must implement .applicable?"
        end

        def apply(scope, params)
          raise NotImplementedError, "#{name} must implement .apply"
        end
      end
    end
  end
end
