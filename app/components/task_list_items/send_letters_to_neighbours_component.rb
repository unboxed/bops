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
        planning_application_publicity_path(
          planning_application,
          consultation
        )
      else
        new_planning_application_publicity_path(
          planning_application
        )
      end
    end

    def status_tag_component
      StatusTags::BaseComponent.new(
        status: if @planning_application.consultation&.neighbour_letters_failed?
                  "failed"
                elsif @planning_application.consultation&.neighbour_letters_sent?
                  "complete"
                else
                  "not_started"
                end
      )
    end
  end
end
