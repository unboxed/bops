# frozen_string_literal: true

class SiteHistory < ApplicationRecord
  include DateValidateable

  belongs_to :planning_application

  alias_attribute :reference, :application_number

  normalizes :decision, with: ->(decision) { normalize_decision(decision) }

  with_options presence: true do
    validates :reference, :description, :decision
    validates :date, date: {before: :current}
  end

  class << self
    private

    def normalize_decision(decision)
      return decision if decision.blank?

      case decision
      when /granted/i
        "granted"
      when /refused/i, /shall not be made/i
        "refused"
      when /not required/i
        "not_required"
      else
        raise ArgumentError, "Unable to normalize decision '#{decision}'"
      end
    end
  end
end
