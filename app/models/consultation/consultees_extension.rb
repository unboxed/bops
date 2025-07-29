# frozen_string_literal: true

class Consultation < ApplicationRecord
  module ConsulteesExtension
    def sorted
      sort_by(&:created_at)
    end

    def internal
      sorted.select(&:internal?)
    end

    def internal_consulted
      internal.select(&:consulted?)
    end

    def external
      sorted.select(&:external?)
    end

    def external_consulted
      external.select(&:consulted?)
    end

    def selected
      sorted.select(&:selected?)
    end

    def none_selected?
      selected.none?
    end

    def consulted
      sorted.select(&:consulted?)
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

    def responded?
      consulted.any?(&:responses?)
    end

    def complete?
      present? && all?(&:responded?)
    end
  end
end
