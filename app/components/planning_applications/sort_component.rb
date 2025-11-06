# frozen_string_literal: true

module PlanningApplications
  class SortComponent < ViewComponent::Base
    def initialize(attribute:, direction:)
      @attribute = attribute
      @direction = direction
    end

    def sort_link(column)
      new_direction = determine_new_direction(column)
      query = request.query_parameters.merge(
        sort_key: column,
        direction: new_direction
      )
      helpers.url_for(
        params: query,
        anchor: "all"
      )
    end

    def sort_class(column, current_sort)
      if current_sort == column
        sort_direction_class
      else
        "unsorted"
      end
    end

    private

    def determine_new_direction(column)
      (params[:sort_key] == column && direction == "asc") ? "desc" : "asc"
    end

    def sort_direction_class
      (direction == "asc") ? "ascending" : "descending"
    end

    attr_reader :attribute, :direction
  end
end
