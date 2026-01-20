# frozen_string_literal: true

module PlanningApplications
  class TabsController < AuthenticationController
    include BopsCore::TabsController

    def updated
      @audits = search.updated_planning_application_audits
      respond_to do |format|
        format.html
      end
    end

    private

    def filtered_applications
      search.filtered_planning_applications
    end

    def closed_applications
      search.closed_planning_applications
    end
  end
end
