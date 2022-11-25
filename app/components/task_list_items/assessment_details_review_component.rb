# frozen_string_literal: true

module TaskListItems
  class AssessmentDetailsReviewComponent < TaskListItems::BaseComponent
    include AssessmentDetailable

    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application, :category

    def link_text
      t(".review_assessment_summaries")
    end

    def link_path
      if assessment_details_review_complete?
        planning_application_assessment_details_review_path(
          planning_application
        )
      else
        edit_planning_application_assessment_details_review_path(
          planning_application
        )
      end
    end

    def status_tag_component
      StatusTags::AssessmentDetailsReviewComponent.new(
        planning_application: planning_application
      )
    end

    def link_active?
      planning_application.awaiting_determination? ||
        planning_application.awaiting_correction?
    end
  end
end
