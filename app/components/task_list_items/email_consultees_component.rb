# frozen_string_literal: true

module TaskListItems
  class EmailConsulteesComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate :consultation, to: :planning_application
    delegate :consultee_emails_status, to: :consultation

    def link_text
      t(".email_consultees")
    end

    def link_path
      planning_application_consultee_emails_path(planning_application)
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status: consultee_emails_status)
    end
  end
end
