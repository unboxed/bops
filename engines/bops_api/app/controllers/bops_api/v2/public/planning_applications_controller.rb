# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class PlanningApplicationsController < PublicController
        def search
          @pagy, @planning_applications = search_service.call

          respond_to do |format|
            format.json
          end
        end

        private

        def planning_applications_scope
          @local_authority.planning_applications.where.not(published_at: nil)
        end

        def search_params
          params.permit(:page, :maxresults, :q)
        end

        def search_service(scope = planning_applications_scope.by_latest_received_and_created)
          @search_service ||= Application::SearchService.new(scope, search_params)
        end
      end
    end
  end
end
