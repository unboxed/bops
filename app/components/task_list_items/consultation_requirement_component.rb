# frozen_string_literal: true

module TaskListItems
  class ConsultationRequirementComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def link_text
      t(".determine_requirement")
    end

    def link_path
      edit_planning_application_consultation_requirement_path(planning_application)
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status: status)
    end

    def status
      if planning_application.consultation_required.nil?
        :not_started
      else
        :complete
      end
    end
  end
end
