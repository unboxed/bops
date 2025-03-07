# frozen_string_literal: true

require "liquid"

class ApplicationType < ApplicationRecord
  class DecisionNotice < ApplicationRecord
    STATUSES = %i[not_started in_progress complete].freeze

    enum :status, STATUSES.index_with(&:to_s), default: "not_started"

    belongs_to :application_type

    validates :template, presence: true

    def render(application)
      liquid_template.render(liquid_context(application))
    end

    private

    def liquid_template
      @liquid_template ||= Liquid::Template.parse(template, environment: liquid_environment)
    end

    def liquid_environment
      Liquid::Environment.build do |environment|
        environment.register_filter(BopsCore::LiquidFilters)
      end
    end

    def liquid_context(application)
      {
        "application" => application,
        "local_authority" => application.local_authority,
        "application_type" => application.application_type
      }
    end
  end
end
