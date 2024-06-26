# frozen_string_literal: true

module PlanningApplications
  module Review
    class PolicyClassesController < BaseController
      before_action :set_policy_class, only: %i[edit update show]

      def show
      end

      def edit
      end

      def update
        if @policy_class.update(policy_class_params)
          redirect_to(planning_application_review_tasks_path(@planning_application),
            notice: t(".successfully_updated_policy_class"))
        else
          render :edit
        end
      end

      private

      def set_policy_class
        @policy_class = PolicyClassPresenter.new(
          @planning_application.policy_classes.find(params[:id])
        )
      end

      def policy_class_params
        params
          .require(:policy_class)
          .permit(policies_attributes: %i[id status],
            reviews_attributes: %i[id action comment])
          .to_h
          .deep_merge(
            reviews_attributes: {"0": {
              review_status: review_status,
              status: policy_class_status
            }}
          )
      end

      def review_status
        mark_as_complete? ? "review_complete" : "review_not_started"
      end

      def policy_class_status
        return_to_officer? ? "to_be_reviewed" : "complete"
      end

      def return_to_officer?
        params.dig(:policy_class, :reviews_attributes)[:"0"][:action] == "rejected"
      end
    end
  end
end
