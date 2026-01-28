# frozen_string_literal: true

module BopsCore
  module Filters
    module TextSearch
      class CascadingSearch
        STRATEGIES = [
          BopsCore::Filters::TextSearch::ReferenceSearch,
          BopsCore::Filters::TextSearch::PostcodeSearch,
          BopsCore::Filters::TextSearch::AddressSearch,
          BopsCore::Filters::TextSearch::DescriptionSearch
        ].freeze

        def applicable?(params)
          query(params).present?
        end

        def apply(scope, params)
          q = query(params)
          return scope.none if q.nil?

          strategies.each do |strategy|
            result = strategy.apply(scope, q)
            return result if result.exists?
          end

          scope.none
        rescue ActiveRecord::StatementInvalid
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
