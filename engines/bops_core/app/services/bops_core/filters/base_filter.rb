# frozen_string_literal: true

module BopsCore
  module Filters
    class BaseFilter
      def applicable?(_params)
        raise NotImplementedError, "#{self.class.name} must implement #applicable?"
      end

      def apply(_scope, _params)
        raise NotImplementedError, "#{self.class.name} must implement #apply"
      end
    end
  end
end
