# frozen_string_literal: true

class SendConsulteeEmailsJob < ApplicationJob
  queue_as :high_priority

  def perform(consultation, consultees, subject, body)
    planning_application = consultation.planning_application
    local_authority = planning_application.local_authority

    defaults = {
      signatory_name: local_authority.signatory_name,
      signatory_job_title: local_authority.signatory_job_title,
      local_authority: local_authority.council_name,
      reference: planning_application.reference,
      description: planning_application.description,
      address: planning_application.address,
      link: consultation.application_link,
      closing_date: consultation.end_date_from_now.to_date.to_fs
    }

    consultees.each do |consultee|
      next if consultee.email_address.blank?

      variables = defaults.merge(name: consultee.name)

      consultee_email = consultee.emails.create!(
        subject: format(subject, variables),
        body: format(body, variables)
      )

      consultee.update!(
        selected: false,
        status: "sending",
        email_sent_at: nil,
        email_delivered_at: nil
      )

      SendConsulteeEmailJob.perform_later(consultation, consultee_email)
    end
  end
end
