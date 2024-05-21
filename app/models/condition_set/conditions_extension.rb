# frozen_string_literal: true

class ConditionSet < ApplicationRecord
  module ConditionsExtension
    def sorted
      sort_by(&:sort_key)
    end

    def standard
      Condition.standard_conditions.map do |condition|
        detect { |c| c.title == condition.title } || condition
      end
    end

    def other
      reject(&:standard?)
    end
  end
end
