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
      return {} unless toggle_options

      {
        controller: "toggle",
        toggle_class_name_value: toggle_options[:class_name],
        toggle_condensed_text_value: toggle_options[:condensed_text],
        toggle_expanded_text_value: toggle_options[:expanded_text]
      }
    end

    def render_left_items
      helpers.content_tag(:ul, class: "bops-header-bar__left", role: "list") do
        items = left_items.map { |item| render_left_text_item(item) }
        items << render_left_toggle_item if toggle_options
        safe_join(items)
      end
    end

    def render_left_text_item(item)
      helpers.content_tag(:li, class: "bops-header-bar__item") do
        helpers.tag.span(item[:text].to_s, class: left_item_class(item))
      end
    end

    def render_left_toggle_item
      helpers.content_tag(:li, class: "bops-header-bar__item--toggle") do
        render_toggle_button
      end
    end

    def left_item_class(item)
      class_names(
        "bops-header-bar__text",
        ("govuk-!-font-weight-bold" if item[:bold].present?),
        item[:class]
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

    def hide_header_links?
      helpers.instance_variable_get(:@hide_application_information_link)
    end

    def toggle_options
      @toggle_options ||= begin
        return nil if toggle.blank?

        content = toggle[:content]
        return nil if content.blank?

        {
          class_name: toggle[:class_name] || "govuk-!-display-none",
          condensed_text: toggle[:condensed_text] || "Show details",
          expanded_text: toggle[:expanded_text] || "Hide details",
          button_class: toggle[:button_class],
          content_class: toggle[:content_class],
          content: content
        }
      end
    end
  end
end
