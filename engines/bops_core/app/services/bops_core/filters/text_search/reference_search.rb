# frozen_string_literal: true

module BopsCore
  module Filters
    module TextSearch
      class ReferenceSearch < BaseSearch
        class << self
          def apply(scope, query)
            scope.where("LOWER(reference) LIKE ?", "%#{query.downcase}%")
          end
        end
      end
    end
  end
end
