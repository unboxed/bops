# frozen_string_literal: true

class UploadDocumentsJob < ApplicationJob
  queue_as :urgent

  def perform(planning_application:, files:)
    UploadDocumentsService.new(
      planning_application: planning_application,
      files: files
    ).call
  end
end
