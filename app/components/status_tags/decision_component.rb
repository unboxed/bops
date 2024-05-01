# frozen_string_literal: true

module StatusTags
  class DecisionComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      super(status:)
    end

    private

    attr_reader :planning_application

    def status
      if planning_application.heads_of_term&.terms&.any?
        :"#{planning_application.decision}_legal_agreement"
      else
        planning_application.decision&.to_sym
      end
    end
  end
end
