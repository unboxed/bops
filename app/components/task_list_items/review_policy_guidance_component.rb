# frozen_string_literal: true

module TaskListItems
  class ReviewPolicyGuidanceComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:policy_guidance, to: :planning_application)

    def link_text
      "Review check against policies and guidance"
    end

    def review_policy_guidance
      policy_guidance.current_review_policy_guidance
    end

    def link_path
      if review_policy_guidance&.reviewed_at.present? &&
         policy_guidance.review_status == "review_complete"
        planning_application_review_policy_guidance_path(
          planning_application,
          review_policy_guidance
        )
      else
        edit_planning_application_review_policy_guidance_path(
          planning_application,
          review_policy_guidance
        )
      end
    end

    def status_tag_component
      StatusTags::ReviewPolicyGuidanceComponent.new(
        planning_application:,
        review_policy_guidance:
      )
    end
  end
end
