# frozen_string_literal: true

module TaskListItems
  class ReviewImmunityEnforcementComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:immunity_detail, to: :planning_application)

    def link_text
      t(".review_immunity_enforcement")
    end

    def review_immunity_detail
      immunity_detail.current_enforcement_review_immunity_detail
    end

    def link_path
      if review_immunity_detail.review_complete?
        planning_application_review_immunity_enforcement_path(
          planning_application,
          review_immunity_detail
        )
      else
        edit_planning_application_review_immunity_enforcement_path(
          planning_application,
          review_immunity_detail
        )
      end
    end

    def status_tag_component
      StatusTags::ReviewImmunityEnforcementComponent.new(
        planning_application:,
        review_immunity_detail:
      )
    end
  end
end
