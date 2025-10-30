# frozen_string_literal: true

module PlanningApplications
  module Information
    class BaseController < AuthenticationController
      include InformationHelper

      before_action :set_planning_application
      before_action :hide_application_information_link
      helper_method :information_navigation_items

      private

      def information_navigation_items
        information_nav_items(@planning_application)
      end

      def hide_application_information_link
        @hide_application_information_link = true
      end
    end
  end
end
