# frozen_string_literal: true

module StatusTags
  class ReviewPolicyGuidanceComponent < StatusTags::BaseComponent
    def initialize(planning_application:, review_policy_area:)
      @planning_application = planning_application
      @review_policy_area = review_policy_area
    end

    private

    attr_reader :planning_application, :review_policy_area

    def status
      if review_policy_area.review_complete?
        :complete
      elsif review_policy_area.review_in_progress?
        :in_progress
      else
        :not_started
      end
    end
  end
end
