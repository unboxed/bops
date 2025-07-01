# frozen_string_literal: true

module PlanningApplications
  class PanelComponent < ViewComponent::Base
    include Pagy::Backend

    def initialize(planning_applications:, type:, search: nil)
      @planning_applications = planning_applications
      @type = type
      @search = search
    end

    attr_reader :type, :search

    def before_render
      @pagy, @paginated_applications = pagy(@planning_applications)
    end

    def planning_applications
      case type
      when :all
        @paginated_applications
      else
        @planning_applications
      end
    end

    def pagination
      return unless @pagy.pages > 1

      page_data = @pagy.series.map { |i|
        {href: pagination_url(page: i), number: i, current: i.to_i == @pagy.page}
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

    def title
      t(".#{type}")
    end

    def attributes
      try("#{type}_attributes") || default_attributes
    end

    def all_attributes
      %i[reference full_address description days_status_tag status_tag formatted_expiry_date user_name]
    end

    def mine_attributes
      %i[reference full_address formatted_expiry_date days_status_tag status_tag]
    end

    def closed_attributes
      %i[reference outcome formatted_outcome_date full_address description]
    end

    def awaiting_determination_attributes
      default_attributes.tap do |array|
        array[5] = :formatted_awaiting_determination_at
      end
    end

    def default_attributes
      %i[
        reference
        full_address
        formatted_expiry_date
        days_status_tag
        status_tag
        user_name
      ]
    end
  end
end
