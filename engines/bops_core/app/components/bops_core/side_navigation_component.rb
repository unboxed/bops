# frozen_string_literal: true

module BopsCore
  class SideNavigationComponent < GovukComponent::Base
    class SectionComponent < GovukComponent::Base
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

        def link_attributes
          {
            class: "bops-side-navigation__link",
            aria: {current: (current ? "true" : nil)}
          }
        end

        def default_attributes
          {
            class: class_names(
              "bops-side-navigation__section-item",
              "bops-side-navigation__section-item--current" => current
            )
          }
        end
      end

      renders_many :navigation_items, "NavigationItemComponent"

      attr_reader :title, :index

      def initialize(title:, index:, navigation_items: [], classes: [], html_attributes: {})
        navigation_items.each do |item|
          with_navigation_item(**item)
        end

        @title = title
        @index = index

        super(classes:, html_attributes:)
      end

      def call
        tag.section(**html_attributes) do
          safe_join([heading, list])
        end
      end

      def heading
        tag.h3(title, **heading_attributes)
      end

      def heading_attributes
        {
          id: "side-navigation-section-#{index}-heading",
          class: "bops-side-navigation__section-heading"
        }
      end

      def list
        tag.ul(**list_attributes) do
          safe_join(navigation_items)
        end
      end

      def list_attributes
        {class: "bops-side-navigation__section-list"}
      end

      def default_attributes
        {
          class: "bops-side-navigation__section",
          aria: {labelledby: "side-navigation-section-#{index}-heading"}
        }
      end
    end

    renders_many :sections, "SectionComponent"

    attr_reader :title

    def initialize(title:, sections: [], classes: [], html_attributes: {})
      sections.each_with_index do |section, index|
        with_section(index:, **section)
      end

      @title = title

      super(classes:, html_attributes:)
    end

    def call
      tag.nav(**html_attributes) do
        safe_join([heading, sections])
      end
    end

    private

    def heading
      tag.h2(title, **heading_attributes)
    end

    def heading_attributes
      {id: "side-navigation-heading", class: "bops-side-navigation__heading"}
    end

    def default_attributes
      {
        class: "bops-side-navigation",
        aria: {labelledby: "side-navigation-heading"}
      }
    end
  end
end
