# frozen_string_literal: true

module PlanningApplications
  class SearchComponent < ViewComponent::Base
    def initialize(panel_type:, search:, tab_route:)
      @panel_type = panel_type
      @search = search
      @tab_route = tab_route
    end

    private

    attr_reader :search, :panel_type, :tab_route

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
      tab_path(
        status: default_statuses,
        application_type: all_application_types
      )
    end

    def tab_path(extra_params = {})
      helpers.public_send(tab_route, extra_params.merge(anchor: "tabs"))
    end
  end
end
