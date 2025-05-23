# frozen_string_literal: true

module BopsApplicants
  class PlanningApplicationsController < ApplicationController
    before_action :set_planning_application

    def show
      respond_to do |format|
        format.html
      end
    end

    private

    def planning_applications_scope
      current_local_authority.planning_applications.published
    end

    def planning_application_param
      params.fetch(:reference)
    end
  end
end
