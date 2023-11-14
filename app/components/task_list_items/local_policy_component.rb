# frozen_string_literal: true

module TaskListItems
  class LocalPolicyComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      @local_policy = @planning_application.local_policy
    end

    private

    attr_reader :local_policy, :planning_application

    def link_text
      t(".link_text")
    end

    def link_path
      if @planning_application.local_policy.present?
        if local_policy.status == "complete"
          planning_application_assessment_local_policy_path(planning_application, local_policy)
        else
          edit_planning_application_assessment_local_policy_path(planning_application, local_policy)
        end
      else
        new_planning_application_assessment_local_policy_path(planning_application)
      end
    end

    def status_tag_component
      StatusTags::BaseComponent.new(
        status:
      )
    end

    def status
      if @planning_application.local_policy.present?
        local_policy.status
      else
        "not_started"
      end
    end
  end
end
