# frozen_string_literal: true

module BopsSubmissions
  class SubmissionProcessorJob < ApplicationJob
    queue_as :submissions

    def perform(submission_id, current_api_user)
      submission = Submission.find(submission_id)
      submission.start! if submission.may_start?

      if submission.planning_portal?
        ZipExtractionService.new(submission:).call
        Application::PlanningPortalCreationService.new(submission:).call!
      elsif submission.odp?
        if submission.request_body.dig(:data, :application, :type, :value) == "breach"
          Enforcement::CreationService.new(submission:, user: current_api_user).call!
        else
          send_email = false # TODO where do we set this from?
          Application::PlanxCreationService.new(
            local_authority: submission.local_authority,
            submission:,
            user: current_api_user,
            params: submission.request_body,
            email_sending_permitted: send_email
          ).call!
        end
      else
        raise "Unknown schema: #{submission.schema}"
      end

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
