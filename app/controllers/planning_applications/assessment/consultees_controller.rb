# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class ConsulteesController < BaseController
      before_action :set_consultation

      def index
        respond_to do |format|
          format.html
        end
      end

      def check
        if @consultation.create_consultees_review!
          redirect_to planning_application_assessment_tasks_path(@planning_application)
        else
          flash.now(alert: "Consultees were not marked as checked for this application")
          render :index
        end
      end
    end
  end
end
