# frozen_string_literal: true

module BopsCore
  class SecondaryNavigationComponent < GovukComponent::Base
    class NavigationItemComponent < GovukComponent::Base
      attr_reader :text, :href, :current

      def initialize(text:, href:, current: false, classes: [], html_attributes: {})
        @text = text
        @href = href
        @current = current

        super(classes:, html_attributes:)
      end

      def call
        tag.li(**html_attributes) do
          tag.a(text, href:, **link_attributes)
        end
      end

      private

      def link_attributes
        {
          class: "x-#{brand}-secondary-navigation__link",
          aria: {current: (current ? "page" : nil)}
        }
      end

      def default_attributes
        {
          class: class_names(
            "x-#{brand}-secondary-navigation__list-item",
            "x-#{brand}-secondary-navigation__list-item--current" => current
          )
        }
      end
    end

    renders_many :navigation_items, "NavigationItemComponent"

    attr_reader :labelled_by, :visually_hidden_title

    def initialize(labelled_by: nil, visually_hidden_title: nil, navigation_items: [], classes: [], html_attributes: {})
      navigation_items.each do |item|
        with_navigation_item(**item)
      end

      @labelled_by = labelled_by
      @visually_hidden_title = visually_hidden_title

      super(classes:, html_attributes:)
    end

    def call
      return unless navigation_items?

      tag.nav(**html_attributes) do
        tag.ul(class: "x-#{brand}-secondary-navigation__list") do
          safe_join(navigation_items)
        end
      end
    end

    private

    def default_attributes
      {class: default_classes, aria: default_aria_attributes}
    end

    def default_classes
      "x-#{brand}-secondary-navigation"
    end

    def default_aria_attributes
      if labelled_by.present?
        {labelledby: labelled_by}
      else
        {label: visually_hidden_title.presence || "Secondary menu"}
      end
    end
  end
end
