# frozen_string_literal: true

module PlanningApplications
  module Review
    class PolicyClassesController < AuthenticationController
      include CommitMatchable
      before_action :set_planning_application
      before_action :ensure_user_is_reviewer
      before_action :set_policy_class, only: %i[edit update show]

      def show
      end

      def edit
        @policy_class.build_review_policy_class if @policy_class.review_policy_class.nil?
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
            review_policy_class_attributes: %i[id mark comment])
          .to_h
          .deep_merge(status: policy_class_status,
            review_policy_class_attributes: {status: review_status})
      end

      def review_status
        mark_as_complete? ? :complete : :not_started
      end

      def policy_class_status
        return_to_officer? ? :to_be_reviewed : @policy_class.status.to_sym
      end

      def return_to_officer?
        params.dig(:policy_class, :review_policy_class_attributes, :mark) == "return_to_officer_with_comment"
      end
    end
  end
end
