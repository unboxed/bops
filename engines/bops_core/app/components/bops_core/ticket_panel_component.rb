# frozen_string_literal: true

module BopsCore
  class TicketPanelComponent < GovukComponent::Base
    COLOURS = %w[grey green turquoise blue red purple pink orange yellow].freeze

    renders_one :body
    renders_one :footer

    attr_reader :id, :colour

    def initialize(colour: nil, id: nil, classes: [], html_attributes: {})
      @id = id
      @colour = colour

      super(classes:, html_attributes:)
    end

    def call
      tag.div(**html_attributes) do
        safe_join([body_wrapper, footer_wrapper].compact_blank)
      end
    end

    private

    def body_wrapper
      tag.div(body, class: "bops-ticket-panel__body")
    end

    def footer_wrapper
      tag.div(footer, class: "bops-ticket-panel__footer")
    end

    def default_attributes
      {id: id, class: ["bops-ticket-panel", colour_class]}
    end

    def colour_class
      return nil if colour.blank?

      fail(ArgumentError, colour_error_message) unless valid_colour?

      "bops-ticket-panel--#{colour}"
    end

    def valid_colour?
      colour.in?(COLOURS)
    end

    def colour_error_message
      "invalid ticket panel colour #{colour}, supported colours are #{COLOURS.to_sentence}"
    end
  end
end
