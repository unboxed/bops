# frozen_string_literal: true

class ConstraintsStatusTagComponent < StatusTagComponent
  def initialize(planning_application:)
    @planning_application = planning_application
  end

  private

  attr_reader :planning_application

  def status
    planning_application.constraints_checked? ? :checked : :not_checked_yet
  end
end
