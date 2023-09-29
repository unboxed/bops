# frozen_string_literal: true

module TaskListItems
  class PolicyAreaComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      @policy_areas = @planning_application.policy_areas
    end

    private

    attr_reader :policy_areas, :planning_application

    def link_text
      "Assess against policies and guidance"
    end

    def link_path
      if @planning_application.policy_areas.any?
        if policy_areas.all? { |area| area.status == "complete" }
          planning_application_policy_area_path(planning_application, policy_area)
        else
          edit_planning_application_policy_area_path(planning_application, policy_area)
        end
      else
        new_planning_application_policy_area_path(planning_application)
      end
    end

    def status_tag_component
      StatusTags::BaseComponent.new(
        status:
      )
    end

    def status
      if @planning_application.policy_areas.any?
        policy_areas.first.status
      else
        "not_started"
      end
    end
  end
end
