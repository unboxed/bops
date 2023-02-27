# frozen_string_literal: true

module PlanningApplications
  class FilterComponent < ViewComponent::Base
    def initialize(filter:)
      @filter = filter
    end

    private

    def filter_types
      %i[
        not_started
        invalidated
        in_assessment
        awaiting_determination
        to_be_reviewed
        closed
      ].compact
    end

    def selected_filters_count
      filter.filter_options&.values&.count("1") || 6
    end

    def filter_checked_status(filter_type)
      if filter.filter_options
        filter.filter_options[filter_type] == "1"
      else
        true
      end
    end

    attr_reader :filter
  end
end
