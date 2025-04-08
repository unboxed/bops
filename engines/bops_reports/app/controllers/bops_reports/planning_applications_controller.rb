# frozen_string_literal: true

module BopsReports
  class PlanningApplicationsController < ApplicationController
    before_action :set_planning_application, only: %i[show]

    def show
      redirect_to main_app.planning_application_path(@planning_application) unless @planning_application.pre_application?

      @summary_of_advice = @planning_application.assessment_details.summary_of_advice.last

      @site_description = @planning_application.site_description

      @constraints = @planning_application.constraints.group_by(&:category)

      respond_to do |format|
        format.html
      end
    end

    private

    def planning_applications_scope
      current_local_authority.planning_applications.accepted
    end

    def set_planning_application
      param = params[planning_application_param]
      application = planning_applications_scope.find_by!(reference: param)

      @planning_application = PlanningApplicationPresenter.new(view_context, application)
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def planning_application_param
      request.path_parameters.key?(:planning_application_reference) ? :planning_application_reference : :reference
    end
  end
end
