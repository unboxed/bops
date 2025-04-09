# frozen_string_literal: true

module BopsReports
  module PlanningApplications
    class BaseController < ApplicationController
      before_action :set_planning_application
      before_action :redirect_to_application_page, unless: :pre_application?

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
    end
  end
end
