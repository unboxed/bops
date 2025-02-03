# frozen_string_literal: true

module BopsCore
  class SubNavigationComponent < GovukComponent::Base
    class NavigationItemComponent < GovukComponent::Base
      class ChildComponent < GovukComponent::Base
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

        def link_attributes
          {
            class: "x-#{brand}-sub-navigation__link",
            aria: {current: (current ? "true" : nil)}
          }
        end

        def default_attributes
          {class: "x-#{brand}-sub-navigation__section-item"}
        end
      end

      renders_many :children, "ChildComponent"

      attr_reader :text, :href, :current, :parent, :theme

      def initialize(text:, href:, current: false, parent: false, theme: nil, children: [], classes: [], html_attributes: {})
        children.each do |child|
          with_child(**child)
        end

        @text = text
        @href = href
        @current = current
        @parent = parent
        @theme = theme

        super(classes:, html_attributes:)
      end

      def call
        tag.li(**html_attributes) do
          safe_join([link, wrapper])
        end
      end

      private

      def link
        tag.a(text, href:, **link_attributes)
      end

      def wrapper
        return unless children?

        tag.ul(**wrapper_attributes) do
          safe_join(children)
        end
      end

      def wrapper_attributes
        {class: "x-#{brand}-sub-navigation__section x-#{brand}-sub-navigation__section--nested"}
      end

      def current_or_parent
        current || parent
      end

      def link_attributes
        {
          class: "x-#{brand}-sub-navigation__link",
          aria: {current: (current ? "true" : nil)}
        }
      end

      def default_attributes
        {
          class: class_names(
            "x-#{brand}-sub-navigation__section-item",
            "x-#{brand}-sub-navigation__section-item--current" => current_or_parent
          )
        }
      end
    end

    renders_many :navigation_items, "NavigationItemComponent"

    attr_reader :visually_hidden_title

    def initialize(visually_hidden_title: nil, navigation_items: [], classes: [], html_attributes: {})
      navigation_items.each do |item|
        with_navigation_item(**item)
      end

      @visually_hidden_title = visually_hidden_title || "Pages in this section"

      super(classes:, html_attributes:)
    end

    def call
      return unless navigation_items?

      tag.nav(**html_attributes) do
        safe_join([heading, grouped_navigation_items])
      end
    end

    private

    def heading
      tag.h2(visually_hidden_title, **heading_attributes)
    end

    def theme_and_list(theme, items)
      if theme.present?
        safe_join([theme_heading(theme), list(items)])
      else
        list(items)
      end
    end

    def theme_heading(theme)
      tag.h3(theme, class: "x-govuk-sub-navigation__theme")
    end

    def list(items)
      tag.ul(**list_attributes) do
        safe_join(items)
      end
    end

    def grouped_navigation_items
      navigation_items.group_by(&:theme).map { |theme, items| theme_and_list(theme, items) }
    end

    def list_attributes
      {class: "x-#{brand}-sub-navigation__section"}
    end

    def heading_attributes
      {id: "sub-navigation-heading", class: "govuk-visually-hidden"}
    end

    def default_attributes
      {
        class: "x-#{brand}-sub-navigation",
        aria: {labelledby: "sub-navigation-heading"}
      }
    end
  end
end
