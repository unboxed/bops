# frozen_string_literal: true

module BopsEnforcements
  class SearchComponent < ViewComponent::Base
    def initialize(panel_type:, search:)
      @panel_type = panel_type
      @search = search
    end

    private

    def all_statuses
      Enforcement.statuses.keys
    end

    attr_reader :search, :panel_type

    def clear_search_url
      helpers.enforcements_path
    end
  end
end
