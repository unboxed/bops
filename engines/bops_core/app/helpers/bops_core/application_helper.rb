# frozen_string_literal: true

module BopsCore
  module ApplicationHelper
    include GOVUKDesignSystemFormBuilder::BuilderHelper

    {
      govuk_primary_navigation: "GovukComponent::PrimaryNavigationComponent",
      govuk_secondary_navigation: "GovukComponent::SecondaryNavigationComponent",
      bops_task_accordion: "BopsCore::TaskAccordionComponent"
    }.each do |name, klass|
      define_method(name) do |*args, **kwargs, &block|
        capture do
          render(klass.constantize.new(*args, **kwargs)) do |com|
            block.call(com) if block.present?
          end
        end
      end
    end

    def active_page_key?(page_key)
      active_page_key == page_key
    end
  end
end
