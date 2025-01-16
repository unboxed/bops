# frozen_string_literal: true

class SiteHistory < ApplicationRecord
  include DateValidateable

  belongs_to :planning_application

  alias_attribute :reference, :application_number

  validates :reference, :description, :decision, presence: true
  validates :date, date: {on_or_before: :current}

  def decision_label
    other_decision? ? decision : I18n.t(decision)
  end

  def decision_type
    other_decision? ? "other" : decision
  end

  def other_decision
    other_decision? ? decision : nil
  end

  def other_decision=(value)
    self.decision = value if other_decision?
  end

  def other_decision?
    decision.present? && Decision.codes.values.exclude?(decision)
  end
end
