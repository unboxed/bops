# frozen_string_literal: true

Govuk::Components.configure do |conf|
  conf.brand_overrides = {
    "GovukComponent::AccordionComponent" => "bops"
  }
end
