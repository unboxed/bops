# frozen_string_literal: true

module PlanningApplications
  module Information
    class BaseController < AuthenticationController
      include InformationHelper

      before_action :set_planning_application
      helper_method :nav_items

      private

      def nav_items
        information_nav_items(@planning_application)
      end
    end
  end
end
