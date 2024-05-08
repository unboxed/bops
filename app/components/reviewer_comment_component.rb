# frozen_string_literal: true

class ReviewerCommentComponent < ViewComponent::Base
  def initialize(comment:)
    @comment = comment
  end

  private

  attr_reader :comment
end
