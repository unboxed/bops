# frozen_string_literal: true

module PlanningApplications
  class FilterComponent < ViewComponent::Base
    def initialize(filter:, current_user:)
      @filter = filter
      @current_user = current_user
    end

    private

    def filter_types
      @current_user.reviewer? ? PlanningApplication::FILTER_OPTIONS[3..4] : PlanningApplication::FILTER_OPTIONS
    end

    def selected_filters_count
      filter.filter_options&.reject(&:empty?)&.count || filter_types.count
    end

    attr_reader :filter
  end
end
