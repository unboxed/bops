# frozen_string_literal: true

class ConsulteeResponseGroupComponent < ViewComponent::Base
  def initialize(consultees:, group:)
    @consultees, @group = consultees, group
  end

  private

  attr_reader :consultees, :group

  def wrapper_tag(&)
    options = {
      id: "#{group}-consultee-responses",
      class: "consultee-responses-group"
    }

    content_tag(:div, **options, &)
  end

  def header_tag(&)
    content_tag(:h2, class: "govuk-heading-m govuk-!-margin-bottom-2", &)
  end

  def header_key
    ".#{group}_header"
  end
end
