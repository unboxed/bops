# frozen_string_literal: true

module BopsCore
  module Filters
    module TextSearch
      class BaseSearch
        class << self
          def apply(scope, query)
            raise NotImplementedError, "#{name} must implement .apply"
          end
        end
      end
    end
  end
end
