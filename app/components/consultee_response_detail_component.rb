# frozen_string_literal: true

class ConsulteeResponseDetailComponent < ViewComponent::Base
  def initialize(response:)
    @response = response
  end

  private

  attr_reader :response

  def wrapper_tag(&)
    content_tag(:div, class: "govuk-details-wrapper", &)
  end

  def details_tag(&)
    content_tag(:details, class: "govuk-details", &)
  end

  def summary_tag(&)
    content_tag(:summary, class: "govuk-details__summary") do
      content_tag(:span, response.name, class: "govuk-details__summary-text")
    end
  end

  def details_text_tag
    content_tag(:div, response.comment, class: "govuk-details__text")
  end

  def status_tag
    content_tag(:div, class: "status-container") do
      response_status
    end
  end

  def response_status
    case response.summary_tag
    when "amendments_needed"
      content_tag(:span, t(".amendments_needed"), class: "govuk-tag govuk-tag--yellow")
    when "objected"
      content_tag(:span, t(".objected"), class: "govuk-tag govuk-tag--red")
    when "approved"
      content_tag(:span, t(".approved"), class: "govuk-tag govuk-tag--green")
    end
  end
end
