# frozen_string_literal: true

module GovukComponent
  class PrimaryNavigationComponent < GovukComponent::Base
    using HTMLAttributesUtils

    class HeadingComponent < GovukComponent::Base
      attr_reader :id, :text

      def initialize(
        id: "primary-navigation-heading",
        text: "Navigation",
        classes: [],
        html_attributes: {}
      )
        @id = id
        @text = text

        super(classes:, html_attributes:)
      end

      def call
        tag.h2(text, id:, **html_attributes)
      end

      private

      def default_attributes
        {class: "govuk-visually-hidden"}
      end
    end

    class ItemComponent < GovukComponent::Base
      attr_reader :link, :current

      def initialize(link:, current: false, classes: [], html_attributes: {})
        @link = link
        @current = current

        super(classes:, html_attributes:)
      end

      def call
        tag.li(**html_attributes) do
          LinkComponent.new(current:, **link).call
        end
      end

      private

      def default_attributes
        {
          class: class_names(
            "x-#{brand}-primary-navigation__item",
            "x-#{brand}-primary-navigation__item--current": current
          )
        }
      end
    end

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
          class: "x-#{brand}-primary-navigation__link",
          aria: {current: (current ? "page" : nil)}
        }
      end
    end

    renders_one :heading, "HeadingComponent"
    renders_many :items, "ItemComponent"

    attr_reader :labelled_by

    def initialize(
      heading: {},
      items: [],
      labelled_by: nil,
      classes: [],
      html_attributes: {}
    )
      @labelled_by = labelled_by

      if heading.present?
        with_heading(**heading)
      end

      items.each do |item|
        with_item(**item)
      end

      super(classes:, html_attributes:)
    end

    def before_render
      with_heading unless labelled_by.present? || heading?
    end

    def call
      return unless items?

      tag.nav(**nav_attributes) do
        tag.div(class: "#{brand}-width-container") do
          safe_join([
            heading,
            tag.ul(class: "x-#{brand}-primary-navigation__list") do
              safe_join(items)
            end
          ])
        end
      end
    end

    private

    def default_attributes
      {class: "x-#{brand}-primary-navigation"}
    end

    def aria_attributes
      if labelled_by.present? || heading?
        {aria: {labelledby: labelled_by || heading.id}}
      else
        {}
      end
    end

    def nav_attributes
      aria_attributes.deep_merge_html_attributes(html_attributes)
    end
  end
end
