# frozen_string_literal: true

require "faraday"

class ConstraintQueryUpdateJob < ApplicationJob
  queue_as :high_priority
  retry_on Faraday::TimeoutError, wait: 5.minutes, jitter: 0

  def perform(planning_application:)
    ConstraintQueryUpdateService.new(
      planning_application:
    ).call
  end
end
