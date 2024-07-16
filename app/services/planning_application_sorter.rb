# frozen_string_literal: true

class PlanningApplicationSorter
  def initialize(scope:, sort_key:, direction:)
    @scope = scope
    @sort_key = sort_key
    @direction = direction
  end

  attr_reader :scope, :sort_key, :direction

  def call
    case sort_key
    when "expiry_date"
      scope.reorder(expiry_date: direction)
    else
      scope
    end
  end
end
