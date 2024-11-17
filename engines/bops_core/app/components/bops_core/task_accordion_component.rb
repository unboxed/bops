# frozen_string_literal: true

module BopsCore
  class TaskAccordionComponent < ViewComponent::Base
    module HTMLAttributes
      extend ActiveSupport::Concern

      using HTMLAttributesUtils

      included do
        attr_reader :html_attributes
      end

      def initialize(**html_attributes)
        @html_attributes = default_attributes
          .deep_merge_html_attributes(html_attributes)
          .deep_tidy_html_attributes
      end

      private

      def default_attributes
        {}
      end
    end

    class HeadingComponent < ViewComponent::Base
      include HTMLAttributes

      attr_reader :text, :level

      def initialize(text:, level: 2, **html_attributes)
        fail(ArgumentError, "level must be 1-6") unless level.in?(1..6)

        @text = text
        @level = level

        super(**html_attributes)
      end

      def call
        content_tag("h#{level}", text, **html_attributes)
      end

      private

      def default_attributes
        {class: "bops-task-accordion-heading"}
      end
    end

    class ExpandAllButtonComponent < ViewComponent::Base
      include HTMLAttributes

      attr_reader :expanded

      def initialize(expanded: false, **html_attributes)
        @expanded = expanded
        super(**html_attributes)
      end

      def call
        tag.button(**html_attributes) do
          tag.span(button_text, **text_attributes)
        end
      end

      private

      def default_attributes
        {
          type: "button",
          aria: {expanded:},
          class: "bops-task-accordion__expand-all",
          data: {
            action: "click->task-accordion#toggleAll"
          }
        }
      end

      def button_text
        expanded ? "Collapse all" : "Expand all"
      end

      def text_attributes
        {class: "bops-task-accordion__expand-all-text"}
      end
    end

    class SectionComponent < ViewComponent::Base
      class HeadingComponent < ViewComponent::Base
        include HTMLAttributes

        attr_reader :text, :level

        def initialize(text:, level: 3, **html_attributes)
          fail(ArgumentError, "level must be 1-6") unless level.in?(1..6)

          @text = text
          @level = level

          super(**html_attributes)
        end

        def call
          content_tag("h#{level}", text, class: "bops-task-accordion__section-heading")
        end
      end

      class ExpandButtonComponent < ViewComponent::Base
        include HTMLAttributes

        attr_reader :expanded

        def initialize(expanded: false, **html_attributes)
          @expanded = expanded
          super(**html_attributes)
        end

        def call
          tag.button(**html_attributes) do
            tag.span(button_text, **text_attributes)
          end
        end

        private

        def default_attributes
          {
            type: "button",
            aria: {expanded:},
            class: "bops-task-accordion__section-expand",
            data: {
              action: "click->task-accordion-section#toggle"
            }
          }
        end

        def button_text
          expanded ? "Collapse" : "Expand"
        end

        def text_attributes
          {class: "bops-task-accordion__section__expand-text"}
        end
      end

      class StatusComponent < ViewComponent::Base
        include HTMLAttributes

        def call
          tag.div(**html_attributes) { content }
        end

        private

        def default_attributes
          {class: "bops-task-accordion__section-status"}
        end
      end

      class FooterComponent < ViewComponent::Base
        include HTMLAttributes

        def call
          tag.div(**html_attributes) { content }
        end

        private

        def default_attributes
          {class: "bops-task-accordion__section-footer"}
        end
      end

      class BlockComponent < ViewComponent::Base
        include HTMLAttributes

        def call
          tag.div(**html_attributes) { content }
        end

        private

        def default_attributes
          {class: "bops-task-accordion__section-block"}
        end
      end

      erb_template <<~ERB
        <%= tag.div(**html_attributes) do %>
          <div class="bops-task-accordion__section-header">
            <%= heading %>
            <%= status %>
            <div class="bops-task-accordion__section-controls">
              <%= expand_button %>
            </div>
          </div>
          <div class="bops-task-accordion__section-content">
            <% blocks.each do |block| %>
              <%= block %>
            <% end %>
            <hr class="bops-task-accordion__section-divider">
            <%= footer %>
          </div>
        <% end %>
      ERB

      include HTMLAttributes

      renders_one :heading, "HeadingComponent"
      renders_one :expand_button, "ExpandButtonComponent"
      renders_one :status, "StatusComponent"
      renders_one :footer, "FooterComponent"
      renders_many :blocks, "BlockComponent"

      attr_reader :expanded

      def before_render
        with_expand_button(expanded: expanded) if expand_button.blank?
      end

      def initialize(heading: {}, expanded: false, **html_attributes)
        @expanded = expanded

        if heading.present?
          with_heading(**heading)
        end

        super(**html_attributes)
      end

      private

      def default_attributes
        {
          class: class_names(
            "bops-task-accordion__section",
            "bops-task-accordion__section--expanded" => expanded
          ),
          data: {
            controller: "task-accordion-section"
          }
        }
      end
    end

    erb_template <<~ERB
      <%= tag.div(**html_attributes) do %>
        <div class="bops-task-accordion-header">
          <%= heading %>
          <div class="bops-task-accordion-controls">
            <%= expand_all_button %>
          </div>
        </div>
        <% sections.each do |section| %>
          <%= section %>
        <% end %>
      <% end %>
    ERB

    include HTMLAttributes

    renders_one :heading, "HeadingComponent"
    renders_one :expand_all_button, "ExpandAllButtonComponent"
    renders_many :sections, "SectionComponent"

    attr_reader :expanded

    def before_render
      with_expand_all_button(expanded: expanded) if expand_all_button.blank?
    end


    def initialize(heading: {}, expanded: false, **html_attributes)
      @expanded = expanded

      if heading.present?
        with_heading(**heading)
      end

      super(**html_attributes)
    end

    private

    def default_attributes
      {
        class: "bops-task-accordion",
        data: {
          controller: "task-accordion",
          action: "task-accordion-section:toggled->task-accordion#sectionToggled"
        }
      }
    end
  end
end
