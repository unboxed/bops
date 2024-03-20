# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class ConsulteesController < ApplicationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :set_consultation

      def index
        respond_to do |format|
          format.html
        end
      end
    end
  end
end
