# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class CommentsController < BaseController
      before_action :set_comment_type, only: %i[create update]

      def create
        new_comment = @comment_type.comments.new(comment_params)
        new_comment = @comment_type.comments.new if new_comment.save
        render(json: {partial: create_comment_partial(new_comment)})
      end

      def update
        comment = @comment_type.comments.find(params[:id])
        comment.update!(deleted_at: DateTime.current)
        render(json: {partial: update_comment_partial})
      end

      private

      def create_comment_partial(new_comment)
        if @comment_type.is_a? Policy
          create_policy_comment_partial(new_comment)
        else
          create_evidence_group_comment_partial(new_comment)
        end
      end

      def create_policy_comment_partial(new_comment)
        render_to_string(
          partial: "planning_applications/review/policy_classes/comment",
          locals: {
            planning_application: @planning_application,
            policy_class:,
            policy:,
            comment: @comment_type.comment,
            new_comment:
          }
        )
      end

      def create_evidence_group_comment_partial(new_comment)
        render_to_string(
          partial: "planning_applications/review/immunity_details/comment",
          locals: {
            planning_application: @planning_application,
            evidence_group:,
            comment: @comment_type.comment,
            new_comment:
          }
        )
      end

      def update_comment_partial
        render_to_string(
          partial: "planning_applications/assessment/policy_classes/comment",
          locals: {
            policy:,
            comment: nil,
            policy_index: params[:policy_index]
          }
        )
      end

      def comment_params
        params.require(:comment).permit(:text)
      end

      def policy
        @policy ||= policy_class.policies.find(params[:policy_id])
      end

      def policy_class
        @planning_application.policy_classes.find(params[:policy_class_id])
      end

      def evidence_group
        @comment_type
      end

      def set_comment_type
        @comment_type = if params[:evidence_group_id].present?
          EvidenceGroup.find(params[:evidence_group_id])
        else
          policy_class.policies.find(params[:policy_id])
        end
      end
    end
  end
end
