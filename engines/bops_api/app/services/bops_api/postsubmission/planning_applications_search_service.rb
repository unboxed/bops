# frozen_string_literal: true

module BopsApi
  module Postsubmission
    class PlanningApplicationsSearchService < Application::SearchService
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
