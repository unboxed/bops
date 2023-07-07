# frozen_string_literal: true

module PlanningApplications
  class SearchComponent < ViewComponent::Base
    def initialize(panel_type:, search:)
      @panel_type = panel_type
      @search = search
    end

    private

    delegate :exclude_others?, to: :search
    attr_reader :search, :panel_type

    def selected_status
      search&.status
    end

    def all_statuses
      search&.statuses
    end

    def selected_status_count
      selected_status&.count || total_status_count
    end

    def total_status_count
      all_statuses.count
    end

    def view
      exclude_others? ? nil : "all"
    end

    def clear_search_url
      planning_applications_path(
        anchor: panel_type,
        view:,
        status: all_statuses
      )
    end
  end
end
