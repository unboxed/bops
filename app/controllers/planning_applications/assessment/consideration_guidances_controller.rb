# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class ConsiderationGuidancesController < BaseController
      before_action :set_consideration_set
      before_action :set_considerations
      before_action :set_consideration

      def create
        @consideration.submitted_by = current_user

        respond_to do |format|
          format.html do
            @consideration.assign_attributes(assessment: "n/a", conclusion: "n/a")
            if @consideration.update(consideration_params, validate: false)
              redirect_to planning_application_assessment_consideration_guidances_path(@planning_application), notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      def index
        @consultee_responses = @planning_application.consultation.consultee_responses

        respond_to do |format|
          format.html
        end
      end

      private

      def set_consideration_set
        @consideration_set = @planning_application.consideration_set
      end

      def set_considerations
        @considerations = @consideration_set.considerations.select(&:persisted?)
      end

      def set_consideration
        @consideration = @consideration_set.considerations.new
      end

      def consideration_params
        params.require(:consideration).permit(:policy_area)
      end
    end
  end
end
