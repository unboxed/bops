# frozen_string_literal: true

module TaskListItems
  class NeighbourResponsesComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:consultation, to: :planning_application)

    def link_text
      t(".neighbour_responses")
    end

    def link_active?
      consultation.present? && consultation.end_date.present?
    end

    def link_path
      return unless link_active?

      planning_application_consultation_neighbour_responses_path(
        planning_application,
        consultation
      )
    end

    def status_tag_component
      StatusTags::BaseComponent.new(
        status:
      )
    end

    def status
      if @planning_application.consultation.nil? || @planning_application.consultation.neighbour_responses.none?
        "not_started"
      elsif @planning_application.consultation.neighbour_responses.any? &&
            @planning_application.consultation.end_date < Time.zone.now
        "complete"
      else
        "in_progress"
      end
    end
  end
end
