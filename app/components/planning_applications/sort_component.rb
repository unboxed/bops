# frozen_string_literal: true

module PlanningApplications
  class SortComponent < ViewComponent::Base
    def initialize(attribute:, direction:)
      @attribute = attribute
      @direction = direction
    end

    def sort_link(column)
      new_direction = determine_new_direction(column)
      url_for(params.to_unsafe_hash.merge(sort_key: column, direction: new_direction))
    end

    def sort_class(column, current_sort)
      if current_sort == column
        sort_direction_class
      else
        "right"
      end
    end

    private

    def determine_new_direction(column)
      (params[:sort_key] == column && direction == "asc") ? "desc" : "asc"
    end

    def sort_direction_class
      (direction == "asc") ? "up" : "down"
    end

    attr_reader :attribute, :direction
  end
end
