# frozen_string_literal: true

module PlanningApplications
  class ImmunityDetailsComponent < ViewComponent::Base
    def initialize(immunity_details:)
      @immunity_details = immunity_details
    end

    attr_reader :immunity_details
  end
end
