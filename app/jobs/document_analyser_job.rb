# frozen_string_literal: true

class DocumentAnalyserJob < ApplicationJob
  queue_as :high_priority
  retry_on(StandardError, attempts: 5, wait: 1.minute, jitter: 0)

  def perform(document)
    DocumentAnalyserService.new(document).call
  end
end
