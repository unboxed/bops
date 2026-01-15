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

        def applicable?(params)
          query(params).present?
        end

        def apply(scope, params)
          q = query(params)

          strategies.each do |strategy|
            result = strategy.apply(scope, q)
            return result if result.exists?
          end

          scope.none
        end

        private

        def strategies
          self.class::STRATEGIES
        end

        def query(params)
          (params[:query] || params[:q]).presence&.downcase&.strip
        end
      end
    end
  end
end
