# frozen_string_literal: true

module StatusTags
  class SignoffRecommendationComponent < StatusTags::BaseComponent
    def initialize(planning_application:, user:)
      @planning_application = planning_application
      @user = user
    end

    private

    attr_reader :planning_application, :user

    def status
      if planning_application.recommendation_review_complete?
        :complete
      elsif planning_application.recommendation_review_in_progress?
        :in_progress
      elsif planning_application.awaiting_determination?
        :not_started
      end
    end
  end
end
