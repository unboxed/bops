# frozen_string_literal: true

module BopsApi
  module Application
    class SubmissionRedactionService
      class RedactionError < StandardError; end

      REDACTION_TEXT = "REDACTED"

      FIELDS_TO_REDACT = [
        ["data", "applicant", "phone", "primary"],
        ["data", "applicant", "phone", "secondary"],
        ["data", "applicant", "email"],
        ["data", "applicant", "agent", "phone", "primary"],
        ["data", "applicant", "agent", "phone", "secondary"],
        ["data", "applicant", "agent", "email"]
      ]

      def initialize(planning_application:)
        @planning_application = planning_application
      end

      def call
        return unless (submission = @planning_application.params_v2)

        redact_fields(submission)
      rescue => e
        raise RedactionError, e.message
      end

      private

      def redact_fields(data)
        FIELDS_TO_REDACT.each do |field_path|
          field = data.dig(*field_path)
          field&.replace(REDACTION_TEXT)
        end

        data
      end
    end
  end
end
