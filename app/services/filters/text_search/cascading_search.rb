# frozen_string_literal: true

module Filters
  module TextSearch
    class CascadingSearch < BaseFilter
      STRATEGIES = [
        BopsCore::Filters::TextSearch::ReferenceSearch,
        BopsCore::Filters::TextSearch::PostcodeSearch,
        BopsCore::Filters::TextSearch::AddressSearch,
        BopsCore::Filters::TextSearch::DescriptionSearch
      ].freeze

      def applicable?(params)
        params[:query].present? && params[:submit].present?
      end

      def apply(scope, params)
        query = params[:query]

        STRATEGIES.each do |strategy|
          result = strategy.apply(scope, query)
          return result if result.exists?
        end

        scope.none
      rescue ActiveRecord::StatementInvalid
        scope.none
      end
    end
  end
end
