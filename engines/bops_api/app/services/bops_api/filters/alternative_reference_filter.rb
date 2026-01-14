# frozen_string_literal: true

module BopsApi
  module Filters
    class AlternativeReferenceFilter < BaseFilter
      class << self
        private

        def applicable?(params)
          params[:alternativeReference].present?
        end

        def apply(scope, params)
          scope.where(
            "alternative_reference ILIKE ?",
            "%#{params[:alternativeReference]}%"
          )
        end
      end
    end
  end
end
