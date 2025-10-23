# frozen_string_literal: true

module BopsCore
  class HeaderBarComponent < ViewComponent::Base
    def initialize(left:, right: [], sticky: true, toggle: nil)
      @left_items = Array.wrap(left)
      @right_items = Array.wrap(right)
      @sticky = sticky
      @toggle = toggle
    end

    private

    attr_reader :left_items, :right_items, :sticky, :toggle

    def container_classes
      class_names("bops-header-bar", sticky ? "bops-header-bar--sticky" : "bops-header-bar--static")
    end

    def container_data_attributes
      return {} unless toggle_options

      {
        controller: "toggle",
        toggle_class_name_value: toggle_options[:class_name],
        toggle_condensed_text_value: toggle_options[:condensed_text],
        toggle_expanded_text_value: toggle_options[:expanded_text]
      }
    end

    def inner_classes = "bops-header-bar__inner"
    def left_stack_classes = "bops-header-bar__left"
    def right_stack_classes = "bops-header-bar__right"
    def divider_classes = "bops-header-bar__divider"
    def base_link_classes = "govuk-link"

    def render_left_items
      nodes = []
      left_items.each_with_index do |item, idx|
        nodes << helpers.tag.span(left_item_text(item), class: left_item_class(item))
        nodes << helpers.tag.div(nil, class: divider_classes) if idx < left_items.size - 1
      end
      safe_join(nodes)
    end

    def left_item_text(item)
      item[:text].to_s
    end

    def left_item_class(item)
      class_names(
        "bops-header-bar__text",
        ("govuk-!-font-weight-bold" if item[:bold].present?),
        item[:class].presence
      )
    end

    def render_toggle_button
      return unless toggle_options

      helpers.button_tag(
        toggle_options[:condensed_text],
        type: "button",
        class: class_names("button-as-link", "govuk-link", "bops-header-bar__toggle-button", toggle_options[:button_class]),
        data: {toggle_target: "button", action: "toggle#click"},
        "aria-expanded": "false"
      )
    end

    def render_toggle_content
      return unless toggle_options

      helpers.tag.div(
        toggle_options[:content],
        class: class_names("bops-header-bar__toggle-panel", toggle_options[:class_name], toggle_options[:content_class]),
        data: {toggle_target: "content"},
        "aria-live": "polite"
      )
    end

    def link_classes(item)
      class_names(base_link_classes, item[:class].presence)
    end

    def right_is_link?(item)
      item[:href].present?
    end

    private

    def toggle_options
      @toggle_options ||= begin
        return nil if toggle.blank?

        content = toggle[:content]
        return nil if content.blank?

        {
          class_name: toggle[:class_name].presence || "govuk-!-display-none",
          condensed_text: toggle[:condensed_text].presence || "Show details",
          expanded_text: toggle[:expanded_text].presence || "Hide details",
          button_class: toggle[:button_class],
          content_class: toggle[:content_class],
          content: content
        }
      end
    end
  end
end
