# frozen_string_literal: true

class PublishDeterminationStatusTagComponent < StatusTagComponent
  def initialize(planning_application:, user:)
    @planning_application = planning_application
    @user = user
  end

  private

  attr_reader :planning_application, :user

  def status
    if planning_application.publish_complete?
      :complete
    elsif planning_application.can_publish? && user.assessor?
      :waiting
    end
  end
end
