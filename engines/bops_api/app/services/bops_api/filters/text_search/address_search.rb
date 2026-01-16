# frozen_string_literal: true

module BopsApi
  module Filters
    module TextSearch
      class AddressSearch < BaseSearch
        class << self
          def apply(scope, query)
            scope.where("address_search @@ to_tsquery('simple', ?)", tsquery_terms(query))
          end

          def tsquery_terms(query)
            query.split.join(" & ")
          end
        end
      end
    end
  end
end
