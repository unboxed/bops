# frozen_string_literal: true

class SearchFormComponent < ViewComponent::Base
  def initialize(search:, panel_type:, exclude_others:)
    @search = search
    @panel_type = panel_type
    @exclude_others = exclude_others
  end

  private

  attr_reader :search, :panel_type, :exclude_others
end
