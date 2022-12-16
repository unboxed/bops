# frozen_string_literal: true

module PolicyClasses
  class CommentFieldComponent < ViewComponent::Base
    include ApplicationHelper

    def initialize(policy:, comment:, policy_index:)
      @policy = policy
      @comment = comment
      @policy_index = policy_index
    end

    private

    attr_reader :policy, :comment, :policy_index

    def error_message
      new_comment.errors.messages[:text].first
    end

    def default_text
      new_comment&.text || comment&.text
    end

    def invalid?
      @invalid ||= new_comment.present? && !new_comment.valid?
    end

    def new_comment
      @new_comment ||= policy.comments.find(&:new_record?)
    end
  end
end
