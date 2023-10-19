# frozen_string_literal: true

class NoConsulteesComponent < ViewComponent::Base
  def initialize(consultees:)
    @consultees = consultees
  end

  private

  attr_reader :consultees

  def wrapper_tag(&)
    options = {
      class: "govuk-body",
      style: consultees.none? ? nil : "display: none;",
      data: {
        consultees_target: "noConsultees"
      }
    }

    content_tag(:p, **options, &)
  end
end
