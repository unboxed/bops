# frozen_string_literal: true

module BopsEnforcements
  class PanelComponent < ViewComponent::Base
    include Pagy::Backend

    def initialize(enforcements:, type:, attributes:, search:)
      @enforcements = enforcements
      @type = type
      @search = search
      @attributes = attributes
    end

    attr_reader :type, :search

    def before_render
      @pagy, @paginated_enforcements = pagy(@enforcements, overflow: :last_page)
    end

    def enforcements
      case type
      when :all
        @paginated_enforcements
      else
        @enforcements
      end
    end

    TAG_MAPPINGS = {
      urgent: ->(e, h) { e.urgent? ? h.govuk_tag(text: "Urgent", colour: "red") : nil },
      days_status_tag: ->(e, h) { h.govuk_tag(text: "#{e.days_from} days received", colour: "orange") },
      status_tag: ->(e, h) { h.govuk_tag(text: e.status.humanize, colour: e.status_tag_colour) },
      to_param: ->(e, h) { h.govuk_link_to(e.case_record.id, h.enforcement_path(e)) }
    }.freeze

    def render_attribute(enforcement, attribute)
      if TAG_MAPPINGS.key?(attribute)
        TAG_MAPPINGS[attribute].call(enforcement, helpers)
      else
        enforcement.send(attribute)
      end
    end

    def pagination
      return unless @pagy.pages > 1

      page_data = @pagy.series.map { |i|
        {href: pagination_url(page: i), number: (i == :gap) ? "…" : i, current: i.is_a?(String)}
      }

      govuk_pagination do |p|
        p.with_previous_page(href: pagination_url(page: @pagy.prev)) if @pagy.page > 1

        p.with_items page_data

        p.with_next_page(href: pagination_url(page: @pagy.next)) if @pagy.page < @pagy.last
      end
    end

    def pagination_url(page:)
      pagy_url_for(@pagy, page) + "##{type}"
    end

    def attributes
      default_attributes
    end

    def title
      t(".#{type}")
    end

    def default_attributes
      %i[
        to_param
        to_s
        days_status_tag
        urgent
        status_tag
      ]
    end
  end
end
