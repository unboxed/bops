# frozen_string_literal: true

module PlanningApplications
  class FilterComponent < ViewComponent::Base
    def initialize(filter:)
      @filter = filter
    end

    private

    def filter_types
      %w[
        not_started
        invalidated
        in_assessment
        awaiting_determination
        awaiting_correction
        closed
      ]
    end

    def selected_filters_count
      filter.filter_options&.reject(&:empty?)&.count
    end

    attr_reader :filter
  end
end
