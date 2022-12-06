# frozen_string_literal: true

module StatusTags
  class PolicyClassComponent < StatusTags::BaseComponent
    def initialize(policy_class:)
      @policy_class = policy_class
    end

    private

    attr_reader :policy_class

    def status
      policy_class.in_assessment? ? :in_progress : policy_class.status.to_sym
    end
  end
end
