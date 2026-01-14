# frozen_string_literal: true

module BopsApi
  module Filters
    module TextSearch
      class BaseSearch
        class << self
          def call(scope, query)
            apply(scope, query)
          end

          private

          def apply(scope, query)
            raise NotImplementedError, "#{name} must implement .apply"
          end
        end
      end
    end
  end
end
