# frozen_string_literal: true

class ConditionSet < ApplicationRecord
  module ConditionsExtension
    def sorted
      sort_by(&:sort_key)
    end
  end
end
