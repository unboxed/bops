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
          @local_authority.planning_applications.published
        end
      end
    end
  end
end
