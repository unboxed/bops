# frozen_string_literal: true

module BopsSubmissions
  class SubmissionProcessorJob < ApplicationJob
    queue_as :submissions

    def perform(submission_id)
      submission = Submission.find(submission_id)
      submission.start! if submission.may_start?

      ZipExtractionService.new(submission:).call
      Application::CreationService.new(submission:).call!

      submission.complete!
    rescue ActiveRecord::RecordNotFound => e
      Appsignal.report_error(e)
      raise
    rescue => e
      submission.fail!
      submission.update!(error_message: e.message)
      raise
    end
  end
end
