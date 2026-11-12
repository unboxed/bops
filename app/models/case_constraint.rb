# frozen_string_literal: true

class CaseConstraint < ApplicationRecord
  belongs_to :constrainable, polymorphic: true
  belongs_to :constraint

  delegate :type, :category, :type_code, to: :constraint

  def entities
    data&.pluck("name", "entity")
  end

  def added?
    true
  end
end
