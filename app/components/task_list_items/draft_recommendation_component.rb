# frozen_string_literal: true

module TaskListItems
  class DraftRecommendationComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:recommendation, to: :planning_application)

    def link_text
      "Make draft recommendation"
    end

    def link_path
      new_planning_application_assessment_recommendation_path(planning_application)
    end

    def link_active?
      planning_application.can_assess?
    end

    def status
      if planning_application.can_assess? && recommendation.blank?
        :not_started
      elsif recommendation&.rejected?
        :to_be_reviewed
      elsif recommendation&.assessment_in_progress?
        :in_progress
      else
        :complete
      end
    end
  end
end
