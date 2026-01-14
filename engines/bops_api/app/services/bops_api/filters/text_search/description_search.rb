# frozen_string_literal: true

module BopsApi
  module Filters
    module TextSearch
      class DescriptionSearch < BaseSearch
        class << self
          private

          def apply(scope, query)
            scope.where(
              "to_tsvector('english', description) @@ to_tsquery('english', ?)",
              tsquery_terms(query)
            )
          end

          def tsquery_terms(query)
            query.split.join(" | ")
          end
        end
      end
    end
  end
end
