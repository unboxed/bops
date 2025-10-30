# frozen_string_literal: true

module PlanningApplications
  module Information
    class BaseController < AuthenticationController
      include InformationHelper

      before_action :set_planning_application
      helper_method :information_navigation_items

      private

      def information_navigation_items
        information_nav_items(@planning_application)
      end
    end
  end
end
