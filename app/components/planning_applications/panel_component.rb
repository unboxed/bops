# frozen_string_literal: true

module PlanningApplications
  class PanelComponent < ViewComponent::Base
    include Pagy::Backend

    def initialize(planning_applications:, type:, search: nil, tab_route: nil)
      @planning_applications = planning_applications
      @type = type
      @search = search
      @tab_route = tab_route
    end

    attr_reader :type, :search, :tab_route

    def before_render
      @pagy, @paginated_applications = pagy(@planning_applications, page_param: page_param, overflow: :last_page)
    end

    def planning_applications
      @paginated_applications
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
      pagy_url_for(@pagy, page, absolute: false)
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
    alias_method :all_pre_apps_attributes, :all_attributes

    def mine_attributes
      %i[reference full_address formatted_expiry_date days_status_tag status_tag]
    end
    alias_method :my_pre_apps_attributes, :mine_attributes

    def unassigned_attributes
      default_attributes
    end
    alias_method :unassigned_pre_apps_attributes, :unassigned_attributes

    def closed_attributes
      %i[reference outcome formatted_outcome_date full_address description]
    end
    alias_method :closed_pre_apps_attributes, :closed_attributes

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

    def page_param
      "page_#{type}"
    end
  end
end
