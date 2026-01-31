# frozen_string_literal: true

module BopsApi
  module Filters
    module Comments
      class QueryFilter
        def applicable?(params)
          params[:query].present?
        end

        def apply(scope, params)
          scope.where("redacted_response ILIKE ?", "%#{params[:query]}%")
        end
      end
    end
  end
end
