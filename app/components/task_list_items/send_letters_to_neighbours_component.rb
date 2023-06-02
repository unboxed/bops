# frozen_string_literal: true

module TaskListItems
  class SendLettersToNeighboursComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:consultation, to: :planning_application)

    def link_text
      t(".send_letters_to_neighbours")
    end

    def link_path
      if consultation.present?
        planning_application_consultation_path(
          planning_application,
          consultation
        )
      else
        new_planning_application_consultation_path(
          planning_application,
        )
      end
    end

    def status_tag_component
      StatusTags::BaseComponent.new(
        status: @planning_application.consultation&.status || "not_started"
      )
    end
  end
end
