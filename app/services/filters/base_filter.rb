# frozen_string_literal: true

module Filters
  class BaseFilter
    def applicable?(params)
      raise NotImplementedError, "#{self.class.name} must implement #applicable?"
    end

    def apply(scope, params)
      raise NotImplementedError, "#{self.class.name} must implement #apply"
    end
  end
end
