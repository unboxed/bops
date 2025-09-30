# frozen_string_literal: true

module TaskListItems
  class SelectConsulteesComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate :consultation, to: :planning_application
    delegate :consultee_emails_status, to: :consultation

    def link_text
      t(".select_consultees")
    end

    def link_active?
      if planning_application.pre_application?
        planning_application.consultation_required?
      else
        true
      end
    end

    def link_path
      planning_application_consultees_path(planning_application)
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status: consultee_emails_status)
    end
  end
end
