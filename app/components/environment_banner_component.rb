# frozen_string_literal: true

class EnvironmentBannerComponent < ViewComponent::Base
  def initialize(display:)
    @display = display
  end

  def render?
    @display
  end
end
