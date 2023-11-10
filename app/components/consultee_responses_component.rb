# frozen_string_literal: true

class ConsulteeResponsesComponent < ViewComponent::Base
  def initialize(consultee:)
    @consultee = consultee
  end

  private

  attr_reader :consultee
  delegate :consultation, to: :consultee
  delegate :planning_application, to: :consultation
  delegate :name, to: :consultee, prefix: true
  delegate :responses, to: :consultee
  delegate :last_response, to: :consultee

  def wrapper_tag(&)
    options = {
      id: "consultee-#{consultee.id}-responses",
      class: "consultee-responses"
    }

    content_tag(:div, **options, &)
  end

  def header_tag(&)
    content_tag(:h3, class: "govuk-heading-s govuk-!-margin-bottom-3 govuk-!-margin-top-3", &)
  end

  def section_break_tag
    tag(:hr, class: "govuk-section-break govuk-section-break--l govuk-section-break--visible")
  end

  def last_response_at
    time_tag(last_response.received_at, format: t(".last_response_at"))
  end

  def last_response_status
    case last_response.summary_tag
    when "amendments_needed"
      content_tag(:span, t(".amendments_needed"), class: "govuk-tag govuk-tag--yellow")
    when "refused"
      content_tag(:span, t(".refused"), class: "govuk-tag govuk-tag--red")
    else
      content_tag(:span, t(".no_objections"), class: "govuk-tag govuk-tag--blue")
    end
  end

  def url_for_document(document)
    if document.published?
      api_v1_planning_application_document_url(document.planning_application, document)
    else
      rails_blob_url(document.file)
    end
  end

  def document_link_tag(document)
    options = {
      class: "govuk-link",
      target: "_blank"
    }

    link_to(document.name, url_for_document(document), **options)
  end

  def view_all_response_link_tag
    options = {
      class: "govuk-link",
      href: planning_application_consultee_responses_path(planning_application, consultee)
    }

    content_tag(:a, t(".view_all_responses", count: responses.size), **options)
  end

  def redact_and_publish_link_tag
    options = {
      class: "govuk-link",
      href: "#"
    }

    content_tag(:a, t(".redact_and_publish"), **options)
  end
end
