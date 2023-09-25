# frozen_string_literal: true

module TaskListItems
  class PolicyGuidanceComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      @policy_guidance = @planning_application.policy_guidance
    end

    private

    attr_reader :policy_guidance, :planning_application

    def link_text
      "Check against policies and guidance"
    end

    def link_path
      if @planning_application.policy_guidance.present?
        if policy_guidance.status == "complete"
          planning_application_policy_guidance_path(planning_application, policy_guidance)
        else
          edit_planning_application_policy_guidance_path(planning_application, policy_guidance)
        end
      else
        new_planning_application_policy_guidance_path(planning_application)
      end
    end

    def status_tag_component
      StatusTags::BaseComponent.new(
        status:
      )
    end

    def status
      if @planning_application.policy_guidance.present?
        policy_guidance.status
      else
        "not_started"
      end
    end
  end
end
