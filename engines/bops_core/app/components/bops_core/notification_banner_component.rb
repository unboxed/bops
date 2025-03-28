# frozen_string_literal: true

module BopsCore
  class NotificationBannerComponent < GovukComponent::Base
    attr_reader :title, :colour, :subheading, :message

    def initialize(title:, colour:, subheading:, message:, classes: [], html_attributes: {})
      @title = title
      @colour = colour
      @subheading = subheading
      @message = message

      super(classes:, html_attributes:)
    end

    def call
      tag.div(**default_attributes) do
        safe_join([header_content, body_content])
      end
    end

    private

    def header_content
      tag.div(class: "govuk-notification-banner__header") do
        tag.h2(title, class: "govuk-notification-banner__title", id: "govuk-notification-banner-title")
      end
    end

    def body_content
      tag.div(class: "govuk-notification-banner__content") do
        safe_join([tag.h2(subheading), tag.p(message)])
      end
    end

    def default_attributes
      {
        role: "region",
        "aria-labelledby": "govuk-notification-banner-title",
        "data-module": "govuk-notification-banner",
        "data-govuk-notification-banner-init": "",
        class: ["govuk-notification-banner", colour_class]
      }
    end

    def colour_class
      "bops-notification-banner--#{colour}"
    end
  end
end
