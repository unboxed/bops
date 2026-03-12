# frozen_string_literal: true

class ConsulteeSummaryComponent < ViewComponent::Base
  def initialize(consultee:)
    @consultee = consultee
  end

  private

  attr_reader :consultee

  with_options to: :consultee do
    delegate :name, :email_address, :last_response, :status
    delegate :organisation, :organisation?, :role, :role?
    delegate :email_delivered_at, :last_received_at
  end

  delegate :summary_tag, to: :last_response

  def consultee_status
    case status
    when "sending"
      content_tag(:span, t("consultee_summary_component.sending"), class: "govuk-tag govuk-tag--grey")
    when "failed"
      content_tag(:span, t("consultee_summary_component.failed"), class: "govuk-tag govuk-tag--red")
    when "awaiting_response"
      content_tag(:span, t("consultee_summary_component.awaiting_response"), class: "govuk-tag govuk-tag--grey")
    when "responded"
      case summary_tag
      when "amendments_needed"
        content_tag(:span, t("consultee_summary_component.amendments_needed"), class: "govuk-tag govuk-tag--yellow")
      when "objected"
        content_tag(:span, t("consultee_summary_component.objected"), class: "govuk-tag govuk-tag--red")
      when "approved"
        content_tag(:span, t("consultee_summary_component.approved"), class: "govuk-tag govuk-tag--green")
      end
    end
  end

  def consulted_at
    email_delivered_at && time_tag(email_delivered_at, format: "%-d %B %Y %H:%M") || "–"
  end

  def latest_received_at
    last_received_at && time_tag(last_received_at, format: "%-d %B %Y %H:%M") || "–"
  end
end
