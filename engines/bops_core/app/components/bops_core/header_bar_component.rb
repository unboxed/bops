# frozen_string_literal: true

module BopsCore
  class HeaderBarComponent < ViewComponent::Base
    def initialize(left:, right: [], toggle: nil)
      @left_items = Array.wrap(left)
      @right_items = Array.wrap(right)
      @toggle = toggle
    end

    def before_render
      @right_items = hide_header_links? ? [] : @right_items
    end

    private

    attr_reader :left_items, :right_items, :toggle

    def container_data_attributes
      return {} unless render_toggle?

      @container_data_attributes ||= {
        controller: "toggle",
        toggle_class_name_value: toggle[:class_name] || "govuk-!-display-none",
        toggle_condensed_text_value: toggle[:condensed_text] || "Show details",
        toggle_expanded_text_value: toggle[:expanded_text] || "Hide details"
      }
    end

    def hide_header_links?
      helpers.instance_variable_get(:@hide_application_information_link)
    end

    def render_toggle?
      toggle.present? && toggle[:content].present?
    end

    def toggle_classes
      class_names("bops-header-bar__toggle-panel", toggle[:class_name] || "govuk-!-display-none", toggle[:content_class])
    end
  end
end
