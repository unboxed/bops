# frozen_string_literal: true

class ReviewerCommentComponent < ViewComponent::Base
  def initialize(comment:)
    @comment = comment
  end

  private

  def sent_at
    (comment.try(:reviewed_at) || comment.created_at).to_fs
  end

  attr_reader :comment
end
