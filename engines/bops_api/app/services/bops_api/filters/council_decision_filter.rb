# frozen_string_literal: true

module BopsApi
  module Filters
    class CouncilDecisionFilter
      def applicable?(params)
        params[:councilDecision].present?
      end

      def apply(scope, params)
        scope.for_council_decision(params[:councilDecision])
      end
    end
  end
end
