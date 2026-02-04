# frozen_string_literal: true

module PlanningApplications
  class UpdatedPanelComponent < ViewComponent::Base
    def initialize(audits:, search:, tab_route:)
      @audits = audits
      @search = search
      @tab_route = tab_route
    end

    attr_reader :audits, :search, :tab_route

    def attributes
      %i[
        formatted_expiry_date
        reference
        status_tag
        full_address
        description
      ]
    end
  end
end
