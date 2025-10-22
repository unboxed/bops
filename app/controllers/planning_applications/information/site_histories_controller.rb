# frozen_string_literal: true

module PlanningApplications
  module Information
    class SiteHistoriesController < BaseController
      def show
        @site_histories = @planning_application.site_histories
      end

      private

      def current_section
        :site_history
      end
    end
  end
end
