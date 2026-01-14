# frozen_string_literal: true

module BopsApi
  module Filters
    module TextSearch
      class CascadingSearch < BaseFilter
        STRATEGIES = [
          ReferenceSearch,
          PostcodeSearch,
          AddressSearch,
          DescriptionSearch
        ].freeze

        class << self
          private

          def applicable?(params)
            query(params).present?
          end

          def apply(scope, params)
            q = query(params)

            STRATEGIES.each do |strategy|
              result = strategy.call(scope, q)
              return result if result.exists?
            end

            DescriptionSearch.call(scope, q)
          end

          def query(params)
            (params[:query] || params[:q]).presence&.downcase&.strip
          end
        end
      end
    end
  end
end
