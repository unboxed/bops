# frozen_string_literal: true

class EnforcementPresenter
  include BopsCore::Presentable

  presents :enforcement
  attr_reader :enforcement

  def initialize(enforcement)
    @enforcement = enforcement
  end

  def status_tag_colour
    "orange"
  end

  def status_tag
    classes = ["govuk-tag govuk-tag--#{status_tag_colour}"]

    tag.span class: classes do
      "unknown"
      # status' to be added later
    end
  end

  def days_status_tag
    classes = ["govuk-tag", "govuk-tag--orange"]

    tag.span class: classes.join(" ") do
      I18n.t("enforcement.days_from", count: days_from)
    end
  end

  def start_investigation_email
    {
      subject: start_investigation_email_subject,
      body: start_investigation_email_body
    }
  end

  def close_investigation_email(**)
    {
      subject: close_investigation_email_subject,
      body: close_investigation_email_body(**)
    }
  end

  private

  def officer_email
    case_record.user_email || local_authority.feedback_email || local_authority.email_address
  end

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
      officer_email:,
      council_name: local_authority.council_name)
  end

  def close_investigation_email_subject
    I18n.t("bops_enforcements.close_investigation_email.subject", ref: case_record.id)
  end

  def close_investigation_email_body(closed_reason:, other_reason:, additional_comment:)
    body_type = (closed_reason == "duplicate") ? "duplicate" : "other"
    reason = (closed_reason == "other") ? other_reason : I18n.t("bops_enforcements.tasks.close-case.show.reason.#{closed_reason}")

    additional_comment = if additional_comment.present?
      if closed_reason == "duplicate"
        " Here are additional comments from the enforcement officer:\n\n-#{additional_comment}"
      else
        "\n- #{additional_comment}"
      end
    end

    I18n.t("bops_enforcements.close_investigation_email.body.#{body_type}",
      ref: case_record.id,
      address: address.to_s,
      received_on: I18n.l(received_at.to_date),
      report_date: I18n.l(received_at.to_date),
      complainant_name: complainant.name,
      reason:,
      additional_comment:,
      officer_email:,
      council_name: local_authority.council_name)
  end
end
