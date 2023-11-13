# frozen_string_literal: true

class ConsulteeOverviewComponent < ViewComponent::Base
  def initialize(consultation:, consultees:)
    @consultation, @consultees = consultation, consultees
  end

  private

  attr_reader :consultation, :consultees
  delegate :planning_application, to: :consultation

  def wrapper_tag(&)
    options = {
      id: "consultee-overview",
      class: "govuk-!-margin-bottom-7"
    }

    content_tag(:div, **options, &)
  end

  def header_tag(&)
    content_tag(:h2, class: "govuk-heading-m govuk-!-margin-bottom-2", &)
  end

  def header_key
    ".overview_header"
  end

  def section_break_tag
    tag(:hr, class: "govuk-section-break govuk-section-break--l govuk-section-break--visible")
  end

  def link_tag(url, &)
    options = {
      class: "govuk-link",
      href: url
    }

    content_tag(:a, **options, &)
  end

  def consultees_emails_path(params)
    planning_application_consultees_emails_path(planning_application, params)
  end

  def chase_outstanding_consultees_path
    consultees_emails_path(reason: "resend")
  end

  def reconsult_existing_consultees_path
    consultees_emails_path(reason: "reconsult")
  end

  def awaiting_responses?
    consultees.any?(&:awaiting_response?)
  end

  def complete?
    consultees.present? && consultees.all?(&:responded?)
  end
end
