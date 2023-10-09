# frozen_string_literal: true

module TaskListItems
  class ReviewLocalPolicyComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:local_policy, to: :planning_application)

    def link_text
      t(".link_text")
    end

    def review_local_policy
      local_policy.current_review_local_policy
    end

    def link_path
      if review_local_policy&.reviewed_at.present? &&
         local_policy.review_status == "review_complete"
        planning_application_review_local_policy_path(
          planning_application,
          review_local_policy
        )
      else
        edit_planning_application_review_local_policy_path(
          planning_application,
          review_local_policy
        )
      end
    end

    def status_tag_component
      StatusTags::ReviewLocalPolicyComponent.new(
        planning_application:,
        review_local_policy:
      )
    end
  end
end
