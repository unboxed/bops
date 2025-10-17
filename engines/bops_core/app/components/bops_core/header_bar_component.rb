# frozen_string_literal: true

module BopsCore
  class HeaderBarComponent < ViewComponent::Base
    def initialize(left:, right: [], sticky: true)
      @left_items = Array.wrap(left)
      @right_items = Array.wrap(right)
      @sticky = sticky
    end

    private

    attr_reader :left_items, :right_items, :sticky

    def container_classes
      class_names("bops-header-bar", sticky ? "bops-header-bar--sticky" : "bops-header-bar--static")
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

    def link_classes(item)
      class_names(base_link_classes, item[:class].presence)
    end

    def right_is_link?(item)
      item[:href].present?
    end
  end
end
