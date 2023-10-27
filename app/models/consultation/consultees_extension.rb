# frozen_string_literal: true

class Consultation < ApplicationRecord
  module ConsulteesExtension
    def internal
      select(&:internal?).sort_by(&:created_at)
    end

    def external
      select(&:external?).sort_by(&:created_at)
    end

    def selected
      select(&:selected?)
    end

    def none_selected?
      selected.none?
    end

    def consulted
      reject(&:not_consulted?)
    end

    def consulted?
      consulted.present?
    end

    def failed?
      consulted.any?(&:failed?)
    end

    def awaiting_responses?
      consulted.any?(&:awaiting_response?)
    end

    def complete?
      consulted.present? && consulted.all?(&:responded?)
    end
  end
end
