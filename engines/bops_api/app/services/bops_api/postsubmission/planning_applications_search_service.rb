# frozen_string_literal: true

module BopsApi
  module Postsubmission
    class PlanningApplicationsSearchService < Application::SearchService
      FILTERS = [
        BopsCore::Filters::TextSearch::CascadingSearch.new,
        Filters::AlternativeReferenceFilter.new,
        Filters::ApplicationTypeFilter.new,
        Filters::ApplicationStatusFilter.new,
        Filters::DateRangeFilter.new(:receivedAt),
        Filters::DateRangeFilter.new(:validatedAt),
        Filters::DateRangeFilter.new(:publishedAt),
        Filters::DateRangeFilter.new(:consultationEndDate)
      ].freeze

      private

      def paginate(scope)
        PostsubmissionPagination.new(scope: scope, params: params).call
      end

      def sorter
        Sorting::Sorter.new(default_field: "published_at")
      end
    end
  end
end
