# frozen_string_literal: true

module PlanningApplications
  class SearchFormComponent < ViewComponent::Base
    def initialize(search:, panel_type:, exclude_others:)
      @search = search
      @panel_type = panel_type
      @exclude_others = exclude_others
    end

    private

    attr_reader :search, :panel_type, :exclude_others

    def clear_search_url
      q = exclude_others ? "exclude_others" : nil
      planning_applications_path(anchor: panel_type, q:)
    end
  end
end
