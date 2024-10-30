# frozen_string_literal: true

class ConsulteeAccordianComponent < ViewComponent::Base
  def initialize(consultees:)
    @consultees = consultees
  end

  private

  attr_reader :consultees

  def accordian_tag(&)
    options = {
      class: "bops-accordion",
      style: consultees.none? ? "display: none;" : nil,
      data: {
        module: "bops-accordion",
        remember_expanded: "false",
        consultees_target: "accordian"
      }
    }

    content_tag(:div, **options, &)
  end
end
