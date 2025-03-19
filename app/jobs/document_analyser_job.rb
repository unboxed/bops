class DocumentAnalyserJob < ApplicationJob
  queue_as :high_priority

  def perform(document)
    DocumentAnalyserService.new(document).call
  end
end
