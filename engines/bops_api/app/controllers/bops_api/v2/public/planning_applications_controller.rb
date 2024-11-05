# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class PlanningApplicationsController < PublicController
        def search
          @pagy, @planning_applications = search_service(planning_applications_scope.by_latest_published).call

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
      end
    end
  end
end
