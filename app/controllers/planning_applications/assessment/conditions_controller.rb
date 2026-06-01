# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class ConditionsController < BaseController
      before_action :set_condition_set
      before_action :ensure_planning_application_is_not_preapp

      def destroy
        @condition = @condition_set.conditions.find(Integer(params[:id]))

        respond_to do |format|
          format.html do
            if @condition.destroy
              redirect_to redirect_path, notice: I18n.t("conditions.destroy.success")
            else
              redirect_to redirect_path, notice: I18n.t("conditions.destroy.failure")
            end
          end
        end
      end

      private

      def redirect_path
        params[:redirect_to]
      end

      def set_condition_set
        @condition_set = @planning_application.condition_set
      end
    end
  end
end
