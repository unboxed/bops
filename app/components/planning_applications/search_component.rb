# frozen_string_literal: true

module PlanningApplications
  class SearchComponent < ViewComponent::Base
    def initialize(panel_type:, search:)
      @panel_type = panel_type
      @search = search
    end

    private

    attr_reader :search, :panel_type

    delegate :all_statuses, :default_statuses, to: :search

    def selected_status
      search&.status
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

    def clear_search_url
      planning_applications_path(
        anchor: panel_type,
        status: default_statuses,
        application_type: all_application_types
      )
    end
  end
end
