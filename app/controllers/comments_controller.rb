# frozen_string_literal: true

class CommentsController < AuthenticationController
  def destroy
    policy.comment.destroy
    render(json: { partial: comment_form })
  end

  private

  def comment_form
    render_to_string(
      partial: "policy_classes/comment_form",
      locals: {
        comment: policy.build_comment,
        policy_index: params[:policy_index]
      }
    )
  end

  def policy
    @policy ||= policy_class.policies.find(params[:policy_id])
  end

  def policy_class
    planning_application.policy_classes.find(params[:policy_class_id])
  end

  def planning_application
    current_local_authority
      .planning_applications
      .find(params[:planning_application_id])
  end
end
