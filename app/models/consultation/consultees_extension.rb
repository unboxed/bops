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
  end
end
