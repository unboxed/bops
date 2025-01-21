# frozen_string_literal: true

module BopsConsultees
  class PlanningApplicationsController < ApplicationController
    before_action :authenticate_with_sgid!
    before_action :set_planning_application, only: :show

    def show
      respond_to do |format|
        format.html
      end
    end

    private

    def set_planning_application
      @planning_application = planning_applications_scope.find_by!(reference:)
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def planning_applications_scope
      @current_local_authority.planning_applications
    end

    def reference
      params[:reference]
    end

    def render_expired
      render "bops_consultees/dashboards/show"
    end
  end
end
