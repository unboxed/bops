# frozen_string_literal: true

class CommentsController < AuthenticationController
  def create
    new_comment = policy.comments.new(comment_params)
    new_comment = policy.comments.new if new_comment.save
    render(json: { partial: create_comment_partial(new_comment) })
  end

  def update
    comment = policy.comments.find(params[:id])
    comment.update(deleted_at: DateTime.current)
    render(json: { partial: update_comment_partial })
  end

  private

  def create_comment_partial(new_comment)
    render_to_string(
      partial: "planning_application/review_policy_classes/comment",
      locals: {
        planning_application:,
        policy_class:,
        policy:,
        comment: policy.comment,
        new_comment:
      }
    )
  end

  def update_comment_partial
    render_to_string(
      partial: "policy_classes/comment",
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
    planning_application.policy_classes.find(params[:policy_class_id])
  end

  def planning_application
    current_local_authority
      .planning_applications
      .find(params[:planning_application_id])
  end
end
