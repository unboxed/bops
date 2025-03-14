# frozen_string_literal: true

module BopsCore
  class StatusDetailComponent < GovukComponent::Base
    renders_one :title
    renders_one :body
    renders_one :status

    attr_reader :id, :open

    def initialize(id: nil, open: false, classes: [], html_attributes: {})
      @id = id
      @open = open
      super(classes:, html_attributes:)
    end

    def before_render
      fail_missing_attributes
    end

    def call
      tag.div(**html_attributes) do
        safe_join([details_block, status_block])
      end
    end

    private

    def fail_missing_attributes
      missing = []
      missing << ":title" unless title?
      missing << ":body" unless body?
      missing << ":status" unless status?

      return if missing.empty?

      raise ArgumentError, "Missing required attributes in StatusDetailComponent: #{missing.join(", ")}"
    end

    def component_classes
      ["govuk-details-wrapper"]
    end

    def default_attributes
      {id: id, class: component_classes}
    end

    def details_block
      tag.details(class: "govuk-details", open: open) do
        safe_join([summary_tag, body_tag])
      end
    end

    def summary_tag
      tag.summary(class: "govuk-details__summary") do
        tag.span(title, class: "govuk-details__summary-text")
      end
    end

    def body_tag
      tag.div(body, class: "govuk-details__text")
    end

    def status_block
      tag.div(status, class: "status-container")
    end
  end
end
