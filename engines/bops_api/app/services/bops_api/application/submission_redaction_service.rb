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

      RESPONSES_TO_REDACT = [
        "Applicant's contact details",
        "Your contact details",
        "Applicant's email address",
        "Applicant's telephone number"
      ]

      def initialize(planning_application:)
        @planning_application = planning_application
      end

      def call
        return unless (submission = planning_application.params_v2)

        redact_fields(redact_responses(submission))
      rescue => e
        raise RedactionError, e.message
      end

      private

      attr_reader :planning_application

      def redact_fields(data)
        FIELDS_TO_REDACT.each do |field_path|
          field = data.dig(*field_path)
          field&.replace(REDACTION_TEXT)
        end

        data["data"]["application"]["fee"] = REDACTION_TEXT
        data
      end

      def redact_responses(submission)
        submission["responses"].each do |response|
          if RESPONSES_TO_REDACT.include?(response["question"])
            response["responses"] = [{"value" => REDACTION_TEXT}]
          end
        end

        submission
      end
    end
  end
end
