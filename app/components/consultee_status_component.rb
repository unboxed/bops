# frozen_string_literal: true

class ConsulteeStatusComponent < ViewComponent::Base
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
    when "not_consulted"
      content_tag(:span, t(".not_consulted"), class: "govuk-tag govuk-tag--grey")
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
      when "objected"
        content_tag(:span, t(".objected"), class: "govuk-tag govuk-tag--red")
      when "approved"
        content_tag(:span, t(".approved"), class: "govuk-tag govuk-tag--green")
      end
    end
  end
end
