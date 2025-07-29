# frozen_string_literal: true

class HistoryReportJob < ApplicationJob
  queue_as :high_priority
  retry_on(StandardError, attempts: 5, wait: 1.minute, jitter: 0)

  def perform(planning_application)
    HistoryReportService.new(planning_application).call
  end
end
