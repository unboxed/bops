# frozen_string_literal: true

module StatusTags
  class ReviewPolicyClassComponent < StatusTags::BaseComponent
    def initialize(policy_class:)
      @policy_class = policy_class
    end

    private

    attr_reader :planning_application

    def status
      @policy_class.review_status.to_sym
    end
  end
end
