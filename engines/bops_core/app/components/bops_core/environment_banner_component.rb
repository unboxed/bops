# frozen_string_literal: true

module BopsCore
  class EnvironmentBannerComponent < ViewComponent::Base
    def render?
      !BopsCore.env.production?
    end

    def call
      tag.div(class: "bops-environment-banner") do
        concat(tag.div(message, class: "govuk-width-container"))
      end
    end

    private

    def message
      "This is #{BopsCore.env}. Only process test cases on this version of BOPS"
    end
  end
end
