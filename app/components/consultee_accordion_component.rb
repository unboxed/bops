# frozen_string_literal: true

class ConsulteeAccordionComponent < ViewComponent::Base
  def initialize(consultees:)
    @consultees = consultees
  end

  private

  attr_reader :consultees

  def accordion_tag(&)
    options = {
      class: "govuk-accordion",
      style: consultees.none? ? "display: none;" : nil,
      data: {
        module: "govuk-accordion",
        remember_expanded: "false",
        consultees_target: "accordion"
      }
    }

    content_tag(:div, **options, &)
  end
end
