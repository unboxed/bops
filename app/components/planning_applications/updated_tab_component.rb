# frozen_string_literal: true

module PlanningApplications
  class UpdatedTabComponent < ViewComponent::Base
    def initialize(audits:)
      @audits = audits
    end

    attr_reader :audits

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
