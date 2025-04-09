# frozen_string_literal: true

module BopsReports
  class PlanningApplicationsController < PlanningApplications::BaseController
    before_action :set_assessment_details
    before_action :set_summary_of_advice
    before_action :set_site_description
    before_action :set_constraints
    before_action :set_recommendation

    def show
      respond_to do |format|
        format.html
      end
    end

    private

    def set_assessment_details
      @assessment_details = @planning_application
    end

    def set_summary_of_advice
      @summary_of_advice = @assessment_details.summary_of_advice
    end

    def set_site_description
      @site_description = @planning_application.site_description
    end

    def set_constraints
      @constraints = @planning_application.constraints.group_by(&:category)
    end

    def set_recommendation
      @recommendation = build_or_find_recommendation
    end

    def build_or_find_recommendation
      if @planning_application.in_assessment? || @planning_application.to_be_reviewed?
        @planning_application.recommendations.new
      elsif @planning_application.awaiting_determination?
        @planning_application.recommendations.last
      end
    end
  end
end
