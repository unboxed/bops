# frozen_string_literal: true

class Consultation < ApplicationRecord
  module ConsulteesExtension
    def by_name(&)
      sort_by { |c| c.values_at(:name, :id) }.each(&)
    end

    def internal
      select(&:internal?)
    end

    def external
      select(&:external?)
    end

    def selected
      select(&:selected?)
    end

    def none_selected?
      selected.none?
    end
  end
end
