# frozen_string_literal: true

module PlanningApplications
  class UpdatedPanelComponent < ViewComponent::Base
    def initialize(audits:, search: nil)
      @audits = audits
      @search = search
    end

    attr_reader :audits, :search

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
