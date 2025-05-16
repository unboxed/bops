# frozen_string_literal: true

module StatusTags
  class RequirementsComponent < StatusTags::BaseComponent
    def initialize(planning_application:, requirements:)
      @planning_application = planning_application
      @requirements = @planning_application.requirements
      super(status:)
    end

    private

    attr_reader :planning_application_requirement

    def status
      if @requirements.any?
        :complete
      elsif @planning_application.recommended_application_type.blank?
        :cannot_start_yet
      else
        :not_started
      end
    end
  end
end
