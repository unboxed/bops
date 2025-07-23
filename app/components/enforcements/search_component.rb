# frozen_string_literal: true

module Enforcements
  class SearchComponent < ViewComponent::Base
    def initialize(panel_type:, search:)
      @panel_type = panel_type
      @search = search
    end

    private

    attr_reader :search, :panel_type

    def clear_search_url
      enforcements_path
    end
  end
end
