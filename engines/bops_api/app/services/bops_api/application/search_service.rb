# frozen_string_literal: true

module BopsApi
  module Application
    class SearchService
      FILTERS = [
        Filters::ApplicationTypeFilter.new,
        Filters::ApplicationStatusFilter.new,
        Filters::DateRangeFilter.new(:receivedAt),
        Filters::DateRangeFilter.new(:validatedAt),
        Filters::DateRangeFilter.new(:publishedAt),
        Filters::DateRangeFilter.new(:consultationEndDate),
        Filters::CouncilDecisionFilter.new,
        Filters::AlternativeReferenceFilter.new,
        BopsCore::Filters::TextSearch::CascadingSearch.new
      ].freeze

      def initialize(scope, params)
        @scope = scope
        @params = params
      end

      def call
        result = filters.reduce(@scope) do |scope, filter|
          filter.applicable?(@params) ? filter.apply(scope, @params) : scope
        end
        result = sorter.call(result, @params)
        paginate(result)
      end

      private

      attr_reader :params

      def filters
        self.class::FILTERS
      end

      def sorter
        Sorting::Sorter.new
      end

      def paginate(scope)
        Pagination.new(scope: scope, params: params).paginate
      end
    end
  end
end
