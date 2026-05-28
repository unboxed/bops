# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class PreCommencementConditionsController < BaseController
      before_action :set_condition_set
      before_action :set_condition
      before_action :ensure_planning_application_is_not_preapp

      def destroy
        respond_to do |format|
          format.html do
            if @condition.destroy
              redirect_to redirect_path, notice: t(".success")
            else
              render :index
            end
          end
        end
      end

      private

      def redirect_path
        params[:redirect_to]
      end

      def set_condition_set
        @condition_set = @planning_application.pre_commencement_condition_set
      end

      def set_condition
        @condition = @condition_set.conditions.find(params[:id])
      end
    end
  end
end
