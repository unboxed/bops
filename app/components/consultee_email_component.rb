# frozen_string_literal: true

class ConsulteeEmailComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end

  private

  attr_reader :form

  def subject_invalid?
    form.object.errors.key?(:consultee_email_subject)
  end

  def body_invalid?
    form.object.errors.key?(:consultee_email_body)
  end

  def message_invalid?
    subject_invalid? || body_invalid?
  end

  def details_tag(&)
    options = {
      class: "govuk-details",
      open: message_invalid?,
      data: {
        module: "govuk-details"
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
    form.govuk_text_field(name, **)
  end

  def text_area_tag(name, **)
    form.govuk_text_area(name, **)
  end

  def hint_tag(&)
    content_tag(:p, class: "govuk-hint", &)
  end
end
