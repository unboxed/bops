# frozen_string_literal: true

module BopsCore
  class TaskAccordionComponent < ViewComponent::Base
    class HeadingComponent < ViewComponent::Base
      attr_reader :text, :level

      def initialize(text:, level: 2)
        fail(ArgumentError, "level must be 1-6") unless level.in?(1..6)

        @text = text
        @level = level
      end

      def call
        content_tag("h#{level}", text, class: "bops-task-accordion-heading")
      end
    end

    class ExpandAllButtonComponent < ViewComponent::Base
      attr_reader :expanded

      def initialize(expanded: false)
        @expanded = expanded
      end

      def call
        tag.button(**button_attributes) do
          tag.span(button_text, **text_attributes)
        end
      end

      private

      def button_attributes
        {
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
        attr_reader :text, :level

        def initialize(text:, level: 3)
          fail(ArgumentError, "level must be 1-6") unless level.in?(1..6)

          @text = text
          @level = level
        end

        def call
          content_tag("h#{level}", text, class: "bops-task-accordion__section-heading")
        end
      end

      class ExpandButtonComponent < ViewComponent::Base
        attr_reader :expanded

        def initialize(expanded: false)
          @expanded = expanded
        end

        def call
          tag.button(**button_attributes) do
            tag.span(button_text, **text_attributes)
          end
        end

        private

        def button_attributes
          {
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

      erb_template <<~ERB
        <%= tag.div(**html_attributes) do %>
          <div class="bops-task-accordion__section-header">
            <%= heading %>
            <div class="bops-task-accordion__section-status">
              <%= status %>
            </div>
            <div class="bops-task-accordion__section-controls">
              <%= expand_button %>
            </div>
          </div>
          <div class="bops-task-accordion__section-content">
            <% blocks.each do |block| %>
              <div class="bops-task-accordion__section-block">
                <%= block %>
              </div>
            <% end %>
            <hr class="bops-task-accordion__section-divider">
            <div class="bops-task-accordion__section-footer">
              <%= footer %>
            </div>
          </div>
        <% end %>
      ERB

      renders_one :heading, "HeadingComponent"
      renders_one :expand_button, "ExpandButtonComponent"
      renders_one :status
      renders_one :footer
      renders_many :blocks

      attr_reader :expanded

      def before_render
        with_expand_button(expanded: expanded) if expand_button.blank?
      end

      def initialize(heading: {}, expanded: false)
        @expanded = expanded

        if heading.present?
          with_heading(**heading)
        end
      end

      private

      def html_attributes
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

    renders_one :heading, "HeadingComponent"
    renders_one :expand_all_button, "ExpandAllButtonComponent"
    renders_many :sections, "SectionComponent"

    attr_reader :expanded

    def before_render
      with_expand_all_button(expanded: expanded) if expand_all_button.blank?
    end

    def initialize(heading: {}, expanded: false)
      @expanded = expanded

      if heading.present?
        with_heading(**heading)
      end
    end

    private

    def html_attributes
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
