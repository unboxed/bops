# frozen_string_literal: true

module BopsReports
  class SendReportEmailJob < ApplicationJob
    queue_as :low_priority

    def perform(planning_application, user)
      return unless planning_application.pre_application?

      ApplicationRecord.transaction do
        planning_application.send_report_mail

        planning_application.audits.create!(
          user: user,
          activity_type: "pre_application_report_sent",
          audit_comment: "Pre-application report was sent"
        )
      end
    end
  end
end
