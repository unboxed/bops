# frozen_string_literal: true

module BopsApi
  module Filters
    class CouncilDecisionFilter < BaseFilter
      class << self
        private

        def applicable?(params)
          params[:councilDecision].present?
        end

        def apply(scope, params)
          scope.for_council_decision(params[:councilDecision])
        end
      end
    end
  end
end
