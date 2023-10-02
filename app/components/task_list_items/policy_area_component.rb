# frozen_string_literal: true

module TaskListItems
  class PolicyAreaComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      @policy_area = @planning_application.policy_area
    end

    private

    attr_reader :policy_area, :planning_application

    def link_text
      "Assess against policies and guidance"
    end

    def link_path
      if @planning_application.policy_area.present?
        if policy_area.status == "complete"
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
      if @planning_application.policy_area.present?
        policy_area.status
      else
        "not_started"
      end
    end
  end
end
