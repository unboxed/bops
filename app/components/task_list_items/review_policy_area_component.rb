# frozen_string_literal: true

module TaskListItems
  class ReviewPolicyAreaComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:policy_area, to: :planning_application)

    def link_text
      t(".link_text")
    end

    def review_policy_area
      policy_area.current_review_policy_area
    end

    def link_path
      if review_policy_area&.reviewed_at.present? &&
         policy_area.review_status == "review_complete"
        planning_application_review_policy_area_path(
          planning_application,
          review_policy_area
        )
      else
        edit_planning_application_review_policy_area_path(
          planning_application,
          review_policy_area
        )
      end
    end

    def status_tag_component
      StatusTags::ReviewPolicyAreaComponent.new(
        planning_application:,
        review_policy_area:
      )
    end
  end
end
