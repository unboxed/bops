# frozen_string_literal: true

class AddConsulteeComponent < ViewComponent::Base
  def initialize(consultees:, form:)
    @consultees = consultees
    @form = form
  end

  private

  attr_reader :consultees, :form

  def details_tag(&)
    options = {
      class: "govuk-details",
      open: consultees.none?,
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

  def container_tag
    klass = %w[
      govuk-!-width-two-thirds
      govuk-!-display-inline-block
    ].join(" ")

    options = {
      id: "add-consultee-container",
      class: klass,
      data: {
        consultees_target: "container"
      }
    }

    content_tag(:div, "", **options)
  end

  def wrapper_tag(&)
    content_tag(:div, class: "govuk-!-margin-top-3", &)
  end

  def label_tag(&)
    options = {
      for: "add-consultee",
      class: "govuk-label--s"
    }

    content_tag(:label, **options, &)
  end

  def hint_tag(&)
    options = {
      id: "add-consultee-hint",
      class: "govuk-hint"
    }

    content_tag(:span, **options, &)
  end

  def button_tag
    klass = %w[
      govuk-button
      govuk-button--secondary
    ].join(" ")

    options = {
      type: "button",
      class: klass,
      data: {
        consultees_target: "addConsultee",
        action: %w[
          click->consultees#addConsulteeClick
        ].join(" ")
      }
    }

    form.button(t(".add_consultee"), **options)
  end
end
