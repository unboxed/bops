# frozen_string_literal: true

module StatusTags
  class PolicyClassComponent < StatusTags::BaseComponent
    def initialize(policy_class:, planning_application:)
      @policy_class = policy_class
      @planning_application = planning_application
    end

    private

    attr_reader :policy_class, :planning_application

    def status
      if to_be_reviewed?
        :to_be_reviewed
      elsif policy_class.in_assessment?
        :in_progress
      elsif policy_class.complete?
        :complete
      end
    end

    def to_be_reviewed?
      planning_application.recommendation&.rejected? &&
        policy_class.update_required?
    end
  end
end
