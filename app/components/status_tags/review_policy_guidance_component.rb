# frozen_string_literal: true

module StatusTags
  class ReviewPolicyGuidanceComponent < StatusTags::BaseComponent
    def initialize(planning_application:, review_policy_guidance:)
      @planning_application = planning_application
      @review_policy_guidance = review_policy_guidance
    end

    private

    attr_reader :planning_application, :review_policy_guidance

    def status
      if review_policy_guidance.review_complete?
        :complete
      elsif review_policy_guidance.review_in_progress?
        :in_progress
      else
        :not_started
      end
    end
  end
end
