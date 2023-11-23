# frozen_string_literal: true

class ConsulteeResponseComponent < ViewComponent::Base
  def initialize(response:)
    @response = response
  end

  private

  attr_reader :response

  with_options to: :response do
    delegate :received_at, :summary_tag
    delegate :consultee, :documents
    delegate :published?
  end

  delegate :consultation, to: :consultee
  delegate :planning_application, to: :consultation

  def response_text
    response.response
  end

  def wrapper_tag(&)
    options = {
      id: "consultee-responses-#{response.id}",
      class: "consultee-response"
    }

    content_tag(:div, **options, &)
  end

  def section_break_tag
    tag(:hr, class: "govuk-section-break govuk-section-break--l govuk-section-break--visible")
  end

  def received_on
    time_tag(received_at, format: t(".received_on"))
  end

  def response_status
    case summary_tag
    when "amendments_needed"
      content_tag(:span, t(".amendments_needed"), class: "govuk-tag govuk-tag--yellow")
    when "objected"
      content_tag(:span, t(".objected"), class: "govuk-tag govuk-tag--red")
    when "approved"
      content_tag(:span, t(".approved"), class: "govuk-tag govuk-tag--green")
    end
  end

  def published_status
    if published?
      content_tag(:span, t(".published"), class: "govuk-tag govuk-tag--green")
    else
      content_tag(:span, t(".private"), class: "govuk-tag govuk-tag--grey")
    end
  end

  def redact_and_publish_link_tag
    options = {
      class: "govuk-link",
      href: edit_planning_application_consultee_response_path(planning_application, consultee, response)
    }

    content_tag(:a, t(".redact_and_publish"), **options)
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
end
