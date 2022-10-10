# frozen_string_literal: true

class SubmitRecommendationStatusTagComponent < StatusTagComponent
  def initialize(planning_application:)
    @planning_application = planning_application
  end

  private

  attr_reader :planning_application

  def status
    :complete if planning_application.submit_recommendation_complete?
  end
end
