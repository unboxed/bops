# frozen_string_literal: true

module StatusTags
  class ConsulteesConsultedComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def status
      assessment_status
    end

    def assessment_status
      if @planning_application.consultees_checked
        :complete
      else
        :not_started
      end
    end
  end
end
