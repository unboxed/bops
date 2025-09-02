# frozen_string_literal: true

class Enforcement < ApplicationRecord
  module Notification
    extend ActiveSupport::Concern

    def start_investigation_email
      {
        subject: start_investigation_email_subject,
        body: start_investigation_email_body
      }
    end

    private

    def start_investigation_email_subject
      I18n.t("bops_enforcements.start_investigation_email.subject", ref: case_record.id)
    end

    def start_investigation_email_body
      I18n.t("bops_enforcements.start_investigation_email.body",
        ref: case_record.id,
        address: address.to_s,
        received_on: I18n.l(received_at.to_date),
        report_date: I18n.l(received_at.to_date),
        complainant_name: complainant.name,
        days: 20,
        officer_email: case_record.user_email || local_authority.feedback_email || local_authority.email_address,
        council_name: local_authority.council_name)
    end
  end
end
