# frozen_string_literal: true

class Consultation < ApplicationRecord
  module ConsulteesExtension
    def internal
      select(&:internal?).sort_by(&:created_at)
    end

    def internal_responses
      internal.select(&:responses?)
    end

    def external
      select(&:external?).sort_by(&:created_at)
    end

    def external_responses
      external.select(&:responses?)
    end

    def selected
      select(&:selected?)
    end

    def none_selected?
      selected.none?
    end

    def consulted
      select(&:consulted?).sort_by(&:created_at)
    end

    def consulted?
      consulted.present?
    end

    def failed?
      any?(&:failed?)
    end

    def awaiting_responses?
      consulted.any?(&:awaiting_response?)
    end

    def responded?
      consulted.any?(&:responses?)
    end

    def complete?
      consulted.present? && consulted.all?(&:responded?)
    end
  end
end
