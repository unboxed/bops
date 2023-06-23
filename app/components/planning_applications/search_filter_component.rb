# frozen_string_literal: true

module PlanningApplications
  class SearchFilterComponent < ViewComponent::Base
    def initialize(current_user:, exclude_others:, panel_type:, search_filter:)
      @panel_type = panel_type
      @exclude_others = exclude_others
      @current_user = current_user
      @search_filter = search_filter
    end

    private

    def filter_types
      if @current_user.reviewer? && @exclude_others
        PlanningApplication::REVIEWER_FILTER_OPTIONS
      else
        PlanningApplication::FILTER_OPTIONS
      end
    end

    def selected_filters_count
      search_filter&.filter_types&.count || 0
    end

    attr_reader :search_filter, :panel_type, :exclude_others

    def clear_search_url
      q = exclude_others ? "exclude_others" : nil
      planning_applications_path(
        anchor: panel_type,
        q:,
        filter_options: PlanningApplication::FILTER_OPTIONS
      )
    end
  end
end
