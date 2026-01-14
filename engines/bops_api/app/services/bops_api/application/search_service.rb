# frozen_string_literal: true

module BopsApi
  module Application
    class SearchService
      FILTERS = [
        Filters::ApplicationTypeFilter,
        Filters::ApplicationStatusFilter,
        Filters::DateRangeFilter.for(:receivedAt),
        Filters::DateRangeFilter.for(:validatedAt),
        Filters::DateRangeFilter.for(:publishedAt),
        Filters::DateRangeFilter.for(:consultationEndDate),
        Filters::CouncilDecisionFilter,
        Filters::AlternativeReferenceFilter,
        Filters::TextSearch::RankedCascadingSearch
      ].freeze

      SORTER = Sorting::Sorter.for(default_field: "received_at")

      def initialize(scope, params)
        @scope = scope
        @params = params
      end

      def call
        result = Filters::FilterChain.apply(FILTERS, @scope, @params)
        result = SORTER.call(result, @params)
        Pagination.new(scope: result, params: @params).paginate
      end
    end
  end
end
