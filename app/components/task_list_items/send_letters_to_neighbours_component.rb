# frozen_string_literal: true

module TaskListItems
  class SendLettersToNeighboursComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate :consultation, to: :planning_application
    delegate :neighbour_letters_status, to: :consultation

    def link_text
      t(".send_letters_to_neighbours")
    end

    def link_path
      planning_application_consultation_neighbour_letters_path(planning_application)
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status: neighbour_letters_status)
    end
  end
end
