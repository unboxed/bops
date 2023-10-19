# frozen_string_literal: true

class ConsulteeEmailComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end

  private

  attr_reader :form

  def details_tag(&)
    options = {
      class: "govuk-details",
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

  def label_tag(name, content)
    form.label(name, content, class: "govuk-label govuk-label--s")
  end

  def text_field_tag(name)
    form.text_field(name, class: "govuk-input")
  end

  def text_area_tag(name, **extra)
    form.text_area(name, **{ class: "govuk-textarea" }.merge(extra))
  end

  def hint_tag(&)
    content_tag(:p, class: "govuk-hint", &)
  end
end
