# frozen_string_literal: true

class ConsulteeEmailComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end

  private

  attr_reader :form

  def subject_invalid?
    form.object.errors.key?(:consultee_message_subject)
  end

  def body_invalid?
    form.object.errors.key?(:consultee_message_body)
  end

  def message_invalid?
    subject_invalid? || body_invalid?
  end

  def default_subject
    form.object.default_consultee_message_subject
  end

  def default_body
    form.object.default_consultee_message_body
  end

  def details_tag(&)
    options = {
      class: "govuk-details",
      open: message_invalid?,
      data: {
        module: "govuk-details",
        controller: "consultee-email",
        consultee_email_default_subject: default_subject,
        consultee_email_default_body: default_body
      }
    }

    content_tag(:details, **options, &)
  end

  def summary_tag(&)
    content_tag(:summary, class: "govuk-details__summary") do
      concat(content_tag(:span, class: "govuk-details__summary-text", &))
    end
  end

  def wrapper_tag(&)
    content_tag(:div, class: "govuk-!-margin-top-3", &)
  end

  def form_group_tag(&)
    content_tag(:div, class: "govuk-form-group", &)
  end

  def text_field_tag(name, **)
    form.govuk_text_field(name, data: {consultee_email_target: "subject"}, **)
  end

  def text_area_tag(name, **)
    form.govuk_text_area(name, data: {consultee_email_target: "body"}, **)
  end

  def button_tag(&)
    options = {
      type: "button",
      class: "govuk-button govuk-button--secondary",
      data: {
        action: "click->consultee-email#reset"
      }
    }
    content_tag(:button, **options, &)
  end

  def hint_tag(&)
    content_tag(:p, class: "govuk-hint", &)
  end
end
