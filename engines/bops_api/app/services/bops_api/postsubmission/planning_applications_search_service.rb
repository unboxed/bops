# frozen_string_literal: true

module BopsApi
  module Postsubmission
    class PlanningApplicationsSearchService
      FILTERS = [
        Filters::TextSearch::CascadingSearch,
        Filters::FieldFilter.for(:reference),
        Filters::FieldFilter.for(:description),
        Filters::FieldFilter.for(:postcode),
        Filters::AlternativeReferenceFilter,
        Filters::ApplicationTypeFilter,
        Filters::ApplicationStatusFilter,
        Filters::DateRangeFilter.for(:receivedAt),
        Filters::DateRangeFilter.for(:validatedAt),
        Filters::DateRangeFilter.for(:publishedAt),
        Filters::DateRangeFilter.for(:consultationEndDate)
      ].freeze

      SORTER = Sorting::Sorter.for(default_field: "published_at")

      def initialize(scope, params)
        @scope = scope
        @params = params
      end

      def call
        result = Filters::FilterChain.apply(FILTERS, @scope, @params)
        result = SORTER.call(result, @params)
        paginate(result)
      end

      private

      attr_reader :params

      def paginate(scope)
        PostsubmissionPagination.new(scope: scope, params: params).call
      end
    end
  end
end
