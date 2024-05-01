# frozen_string_literal: true

module GovukComponent
  class SecondaryNavigationComponent < GovukComponent::Base
    class ItemComponent < GovukComponent::Base
      class LinkComponent < GovukComponent::Base
        attr_reader :text, :href, :current

        def initialize(text:, href:, current:, classes: [], html_attributes: {})
          @text = text
          @href = href
          @current = current

          super(classes:, html_attributes:)
        end

        def call
          tag.a(text, href:, **html_attributes)
        end

        private

        def default_attributes
          {
            class: "x-#{brand}-secondary-navigation__link",
            aria: {current: (current ? "page" : nil)}
          }
        end
      end

      renders_one :link, ->(text:, href:, classes: [], html_attributes: {}, &block) do
        LinkComponent.new(text:, href:, classes:, html_attributes:, current: @current, &block)
      end

      attr_reader :current

      def initialize(link: nil, current: false, classes: [], html_attributes: {})
        @current = current

        if link.present?
          with_link(**link)
        end

        super(classes:, html_attributes:)
      end

      def call
        tag.li(link, **html_attributes)
      end

      private

      def default_attributes
        {
          class: class_names(
            "x-#{brand}-secondary-navigation__list-item",
            "x-#{brand}-secondary-navigation__list-item--current": current
          )
        }
      end
    end

    renders_many :items, "ItemComponent"

    attr_reader :label

    def initialize(label: nil, items: [], classes: [], html_attributes: {})
      items.each do |item|
        with_item(**item)
      end

      @label = label

      super(classes:, html_attributes:)
    end

    def call
      return unless items?

      tag.nav(**html_attributes) do
        tag.ul(class: "x-#{brand}-secondary-navigation__list") do
          safe_join(items)
        end
      end
    end

    private

    def default_attributes
      {
        class: "x-#{brand}-secondary-navigation",
        aria: {label: label || "Secondary Navigation"}
      }
    end
  end
end
