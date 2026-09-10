# frozen_string_literal: true

module BopsEnforcements
  class UpdatedPanelComponent < ViewComponent::Base
    def initialize(audits:, search:, tab_route:)
      @audits = audits
      @search = search
      @tab_route = tab_route
    end

    attr_reader :audits, :search, :tab_route

    def attributes
      %i[
        reference
        status
        full_address
        description
      ]
    end
  end
end
