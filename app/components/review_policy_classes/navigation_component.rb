# frozen_string_literal: true

module ReviewPolicyClasses
  class NavigationComponent < ViewComponent::Base
    def initialize(policy_class:)
      @policy_class = policy_class
    end

    private

    def multiple_policy_classes?
      @policy_class.planning_application.policy_classes.count > 1
    end
  end
end
