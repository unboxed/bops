# frozen_string_literal: true

module BopsReports
  module PlanningApplications
    class BaseController < ApplicationController
      before_action :set_planning_application
      before_action :redirect_to_application_page, unless: :pre_application?
      before_action :set_assessment_details
      before_action :set_summary_of_advice
      before_action :set_site_description
      before_action :set_constraints
      before_action :set_recommendation

      delegate :pre_application?, to: :@planning_application

      private

      def get_planning_application(param)
        planning_applications_scope.find_by!(reference: param)
      end

      def set_planning_application
        param = params[planning_application_param]
        application = get_planning_application(param)

        @planning_application = PlanningApplicationPresenter.new(view_context, application)
      end

      def planning_applications_scope
        current_local_authority.planning_applications.accepted
      end

      def planning_application_param
        request.path_parameters.key?(:planning_application_reference) ? :planning_application_reference : :reference
      end

      def redirect_to_application_page
        redirect_to main_app.planning_application_url(@planning_application)
      end

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
end
