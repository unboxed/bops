# frozen_string_literal: true

module Filters
  class StatusFilter < BaseFilter
    def applicable?(params)
      normalized_statuses(params).present?
    end

    def apply(scope, params)
      scope.where(status: normalized_statuses(params))
    end

    private

    def normalized_statuses(params)
      Array(params[:status]).compact_blank
    end
  end
end
