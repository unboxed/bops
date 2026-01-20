# frozen_string_literal: true

module Filters
  class ApplicationTypeFilter < BaseFilter
    def initialize(local_authority)
      @local_authority = local_authority
    end

    def applicable?(params)
      params[:application_type].present?
    end

    def apply(scope, params)
      type_ids = @local_authority.application_types.where(name: params[:application_type]).ids
      return scope if type_ids.empty?

      scope.where(application_type_id: type_ids)
    end
  end
end
