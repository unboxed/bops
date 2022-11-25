# frozen_string_literal: true

class CommentsController < AuthenticationController
  def destroy
    comment.destroy
    render(json: { partial: destroy_comment_form })
  end

  def update
    comment.update(comment_params)
    render(json: { partial: update_comment_form })
  end

  private

  def update_comment_form
    render_to_string(
      partial: "planning_application/review_policy_classes/comment",
      locals: {
        planning_application: planning_application,
        policy_class: policy_class,
        policy: policy,
        comment: comment
      }
    )
  end

  def destroy_comment_form
    render_to_string(
      partial: "policy_classes/comment_form",
      locals: {
        comment: policy.build_comment,
        policy_index: params[:policy_index]
      }
    )
  end

  def comment_params
    params.require(:comment).permit(:text)
  end

  def comment
    @comment ||= policy.comment
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
