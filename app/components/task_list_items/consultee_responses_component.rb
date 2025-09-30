# frozen_string_literal: true

module TaskListItems
  class ConsulteeResponsesComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate :consultation, to: :planning_application
    delegate :consultee_responses_status, to: :consultation
    delegate :consultees, to: :consultation

    def link_text
      t(".consultee_responses")
    end

    def link_active?
      if planning_application.pre_application?
        planning_application.consultation_required?
      else
        true
      end
    end

    def link_path
      planning_application_consultees_responses_path(planning_application)
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status: consultee_responses_status)
    end
  end
end
