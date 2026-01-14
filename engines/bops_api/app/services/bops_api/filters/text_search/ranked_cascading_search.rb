# frozen_string_literal: true

module BopsApi
  module Filters
    module TextSearch
      class RankedCascadingSearch < BaseFilter
        STRATEGIES = [
          ReferenceSearch,
          PostcodeSearch,
          AddressSearch
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

            RankedDescriptionSearch.call(scope, q)
          end

          def query(params)
            params[:q].presence&.downcase&.strip
          end
        end
      end
    end
  end
end
