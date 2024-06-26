# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class PolicyClassesController < BaseController
      before_action :set_policy_class, only: %i[edit show update destroy]
      before_action :ensure_can_assess_planning_application, only: %i[part new create]

      def part
        @part_number = params[:part]&.to_i
      end

      def show
      end

      def new
        @part = params[:part]

        return if @part.present?

        redirect_to part_new_planning_application_assessment_policy_class_path(@planning_application),
          alert: t(".failure")
      end

      def edit
      end

      def create
        class_ids = planning_application_params[:policy_classes].compact_blank

        if class_ids.empty?
          success_redirect_url
          return
        end

        classes = PolicyClass
          .classes_for_part(params[:part])
          .select { |c| class_ids.include?(c.section) }

        @planning_application.policy_classes += classes

        if @planning_application.save
          success_redirect_url
        else
          redirect_to new_planning_application_assessment_policy_class_path(@planning_application, part: params[:part]),
            alert: @planning_application.errors.full_messages
        end
      end

      def update
        if @policy_class.update(policy_class_params)
          @policy_class.current_review&.update!(status: "updated") if @policy_class.current_review&.review_status == "review_complete"
          redirect_to(post_update_path, notice: t(".successfully_updated_policy"))
        else
          render :edit
        end
      end

      def destroy
        @planning_application.policy_classes.delete(@policy_class.id)

        redirect_to @planning_application, notice: t(".success") if @planning_application.save
      end

      private

      def post_update_path
        if commit_matches?(/view previous/)
          @policy_class.previous.default_path
        elsif commit_matches?(/view next/)
          @policy_class.next.default_path
        else
          planning_application_assessment_tasks_path(@planning_application)
        end
      end

      def planning_application_params
        params.permit(:part, policy_classes: [])
      end

      def policy_class_params
        params
          .require(:policy_class)
          .permit(policies_attributes: [:id, :status, {comments_attributes: [:text]}])
          .merge(reviews_attributes: [
            status:,
            id: (@policy_class&.current_review&.id if same_review?)
          ])
      end

      def set_policy_class
        @policy_class = PolicyClassPresenter.new(
          @planning_application.policy_classes.find(params[:id])
        )
      end

      def ensure_can_assess_planning_application
        render plain: "forbidden", status: :forbidden and return unless @planning_application.can_assess?
      end

      def status
        if mark_as_complete?
          if @policy_class.current_review.present? && @policy_class.current_review.status == "to_be_reviewed"
            "updated"
          else
            "complete"
          end
        else
          "in_progress"
        end
      end

      def success_redirect_url
        redirect_to planning_application_assessment_tasks_path(@planning_application),
          notice: t(".success")
      end

      def same_review?
        mark_as_complete? && @policy_class&.current_review&.status != "to_be_reviewed"
      end
    end
  end
end
