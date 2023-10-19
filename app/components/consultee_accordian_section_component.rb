# frozen_string_literal: true

class ConsulteeAccordianSectionComponent < ViewComponent::Base
  def initialize(consultees:, origin:)
    @consultees = consultees
    @origin = origin
  end

  private

  attr_reader :consultees, :origin

  def section_tag(&)
    klass = %w[
      govuk-accordion__section
      govuk-accordion__section--expanded
    ].join(" ")

    options = {
      id: "#{origin}-consultees",
      class: klass,
      style: consultees.none? ? "display: none;" : nil,
      data: {
        consultees_target: "#{origin}Consultees"
      }
    }

    content_tag(:div, **options, &)
  end

  def toggle_all_tag
    name = "toggle-#{origin}-consultees"
    value = "1"
    checked = consultees.all?(&:selected?)

    options = {
      class: "govuk-checkboxes__input",
      name: nil,
      data: {
        action: "change->consultees#toggle#{origin.upcase_first}Consultees"
      }
    }

    check_box_tag(name, value, checked, **options)
  end
end
