# frozen_string_literal: true

module TaskListItems
  class SelectNeighboursComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate :consultation, to: :planning_application

    def link_text
      t(".select_neighbours")
    end

    def link_path
      planning_application_consultation_neighbours_path(planning_application)
    end

    def status
      if consultation.neighbours.any?
        :in_progress
      else
        :not_started
      end
    end
  end
end
