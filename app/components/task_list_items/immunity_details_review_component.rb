# frozen_string_literal: true

module TaskListItems
  class ImmunityDetailsReviewComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:immunity_detail, to: :planning_application)

    def link_text
      t(".evidence_of_immunity")
    end

    def link_path
      if immunity_detail.review_complete?
        planning_application_review_immunity_detail_path(
          planning_application,
          immunity_detail
        )
      else
        edit_planning_application_review_immunity_detail_path(
          planning_application,
          immunity_detail
        )
      end
    end

    def status_tag_component
      StatusTags::ImmunityDetailReviewComponent.new(
        planning_application:,
        immunity_detail:
      )
    end
  end
end
