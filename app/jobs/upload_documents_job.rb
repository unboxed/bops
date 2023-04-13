# frozen_string_literal: true

class UploadDocumentsJob < ApplicationJob
  queue_as :high_priority

  def perform(planning_application:, files:)
    UploadDocumentsService.new(
      planning_application:,
      files:
    ).call
  end
end
