# frozen_string_literal: true

class PlanningApplicationFilter
  include ActiveModel::Model

  attr_accessor :filter_options, :planning_applications

  def results
    records_matching_query || []
  end

  def filter_types
    filter_options.keys.select { |key| filter_options[key] == "1" }.map { |x| x == "to_be_reviewed" ? "awaiting_correction" : x }
  end

  private

  def records_matching_query
    records_matching_reference.presence
  end

  def records_matching_reference
    planning_applications.where(
      status: [filter_types]
    )
  end
end
