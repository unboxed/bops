# frozen_string_literal: true

module BopsApi
  module Filters
    module TextSearch
      class ReferenceSearch < BaseSearch
        class << self
          private

          def apply(scope, query)
            scope.where("LOWER(reference) LIKE ?", "%#{query}%")
          end
        end
      end
    end
  end
end
