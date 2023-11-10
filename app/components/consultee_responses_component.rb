# frozen_string_literal: true

class ConsulteeResponsesComponent < ViewComponent::Base
  def initialize(consultee:)
    @consultee = consultee
  end

  private

  attr_reader :consultee

  with_options to: :consultee do
    delegate :consultation
    delegate :name, prefix: true
    delegate :awaiting_response?, :responded?
    delegate :responses, :responses?
    delegate :last_response
  end

  delegate :planning_application, to: :consultation

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

  def last_email_delivered_at
    time_tag(consultee.last_email_delivered_at, format: t(".last_email_delivered_at"))
  end

  def last_response_at
    time_tag(consultee.last_response_at, format: t(".last_response_at"))
  end

  def consultee_status
    case consultee.status
    when "sending"
      content_tag(:span, t(".sending"), class: "govuk-tag govuk-tag--grey")
    when "failed"
      content_tag(:span, t(".failed"), class: "govuk-tag govuk-tag--red")
    when "awaiting_response"
      content_tag(:span, t(".awaiting_response"), class: "govuk-tag govuk-tag--grey")
    when "responded"
      case last_response.summary_tag
      when "amendments_needed"
        content_tag(:span, t(".amendments_needed"), class: "govuk-tag govuk-tag--yellow")
      when "refused"
        content_tag(:span, t(".refused"), class: "govuk-tag govuk-tag--red")
      when "no_objections"
        content_tag(:span, t(".no_objections"), class: "govuk-tag govuk-tag--blue")
      end
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

  def view_responses_link_tag
    options = {
      class: "govuk-link",
      href: planning_application_consultee_path(planning_application, consultee)
    }

    if responded?
      content_tag(:a, t(".view_all_responses", count: responses.size), **options)
    else
      content_tag(:a, t(".view_previous_responses", count: responses.size), **options)
    end
  end

  def upload_new_response_link_tag
    options = {
      class: "govuk-link",
      href: new_planning_application_consultee_response_path(planning_application, consultee)
    }

    content_tag(:a, t(".upload_new_response"), **options)
  end
end
