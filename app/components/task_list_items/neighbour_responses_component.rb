# frozen_string_literal: true

module TaskListItems
  class NeighbourResponsesComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate :consultation, to: :planning_application
    delegate :neighbour_responses_status, to: :consultation

    def link_text
      t(".neighbour_responses")
    end

    def link_active?
      consultation.end_date.present?
    end

    def link_path
      planning_application_consultation_neighbour_responses_path(planning_application)
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status: neighbour_responses_status)
    end
  end
end
