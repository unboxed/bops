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

    def review_immunity_detail
      immunity_detail.current_review_immunity_detail
    end

    def link_path
      if immunity_detail.current_review_immunity_detail.reviewed_at.present? &&
         immunity_detail.review_status == "review_complete"
        planning_application_review_immunity_detail_path(
          planning_application,
          review_immunity_detail
        )
      else
        edit_planning_application_review_immunity_detail_path(
          planning_application,
          review_immunity_detail
        )
      end
    end

    def status_tag_component
      StatusTags::ImmunityDetailReviewComponent.new(
        planning_application:,
        review_immunity_detail:
      )
    end
  end
end
