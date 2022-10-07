# frozen_string_literal: true

class AssessRecommendationStatusTagComponent < StatusTagComponent
  def initialize(planning_application:)
    @planning_application = planning_application
  end

  private

  attr_reader :planning_application

  delegate(:recommendation, to: :planning_application)

  def status
    if planning_application.can_assess? && recommendation.blank?
      :not_started
    elsif recommendation&.assessment_in_progress?
      :in_progress
    elsif recommendation&.unchallenged?
      :complete
    end
  end
end
