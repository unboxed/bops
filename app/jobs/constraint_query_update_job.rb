# frozen_string_literal: true

class ConstraintQueryUpdateJob < ApplicationJob
  queue_as :high_priority

  def perform(planning_application:)
    ConstraintQueryUpdateService.new(
      planning_application:
    ).call
  end
end
