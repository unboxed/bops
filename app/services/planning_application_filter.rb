# frozen_string_literal: true

class PlanningApplicationFilter
  include ActiveModel::Model

  attr_accessor :filter_options, :planning_applications, :user

  def results
    records_matching_reference || []
  end

  def filter_types
    filter_options.reject(&:empty?)
  end

  def filtered_filter_types
    filter_types.map { |x| x == "to_be_reviewed" ? "awaiting_correction" : x }
  end

  private

  def records_matching_query
    records_matching_reference.presence
  end

  def records_matching_reference
    filtered_filter_types.map { |filter| planning_applications.send(filter) }.flatten
  end
end
