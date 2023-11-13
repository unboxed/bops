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
    delegate :email_delivered_at, :last_response_at
  end

  delegate :summary_tag, to: :last_response

  def consultee_status
    case status
    when "sending"
      content_tag(:span, t(".sending"), class: "govuk-tag govuk-tag--grey")
    when "failed"
      content_tag(:span, t(".failed"), class: "govuk-tag govuk-tag--red")
    when "awaiting_response"
      content_tag(:span, t(".awaiting_response"), class: "govuk-tag govuk-tag--grey")
    when "responded"
      case summary_tag
      when "amendments_needed"
        content_tag(:span, t(".amendments_needed"), class: "govuk-tag govuk-tag--yellow")
      when "refused"
        content_tag(:span, t(".refused"), class: "govuk-tag govuk-tag--red")
      when "no_objections"
        content_tag(:span, t(".no_objections"), class: "govuk-tag govuk-tag--blue")
      end
    end
  end

  def consulted_on
    email_delivered_at && time_tag(email_delivered_at, format: "%-d %B %Y") || "–"
  end

  def last_response_on
    last_response_at && time_tag(last_response_at, format: "%-d %B %Y") || "–"
  end
end
