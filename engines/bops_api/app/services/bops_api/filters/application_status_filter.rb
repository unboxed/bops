# frozen_string_literal: true

module BopsApi
  module Filters
    class ApplicationStatusFilter < BaseFilter
      class << self
        private

        def applicable?(params)
          params[:applicationStatus].present?
        end

        def apply(scope, params)
          scope.where(status: normalized_statuses(params))
        end

        def normalized_statuses(params)
          Array(params[:applicationStatus])
            .flat_map { |status| status.to_s.split(",") }
            .compact_blank
            .uniq
        end
      end
    end
  end
end
