# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class ConsiderationGuidancesController < BaseController
      before_action :set_consideration_set
      before_action :set_consideration

      def destroy
        respond_to do |format|
          format.html do
            if @consideration.destroy
              redirect_to return_path, notice: t(".success")
            else
              redirect_to return_path, notice: t(".failure")
            end
          end
        end
      end

      private

      def set_consideration_set
        @consideration_set = @planning_application.consideration_set
      end

      def set_consideration
        @consideration = @consideration_set.considerations.find_by_id(consideration_id)
      end

      def consideration_id
        Integer(params[:id])
      end

      def return_path
        params[:return_to].presence
      end
    end
  end
end
