# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class PlanningApplicationsController < PublicController
        def search
          @total_available_items = planning_applications_scope.by_latest_published.count

          @pagy, @planning_applications = BopsApi::Postsubmission::PlanningApplicationsSearchService
            .new(planning_applications_scope.by_latest_published, pagination_params).call

          respond_to do |format|
            format.json
          end
        end

        def show
          @planning_application = find_planning_application params[:id]

          respond_to do |format|
            format.json
          end
        end

        private

        def pagination_params
          params.permit(:sortBy, :orderBy, :resultsPerPage, :query, :page, :format, :reference, :description, :postcode, :publishedAtFrom, :publishedAtTo)
        end
      end
    end
  end
end
