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

    def total_status_count
      all_statuses.count
    end

    def selected_application_type
      search&.application_type
    end

    def all_application_types
      search&.application_types
    end

    def view
      exclude_others? ? nil : "all"
    end

    def clear_search_url
      planning_applications_path(
        anchor: panel_type,
        view:,
        status: all_statuses,
        application_type: all_application_types
      )
    end
  end
end
