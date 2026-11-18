# frozen_string_literal: true

class CaseConstraint < ApplicationRecord
  belongs_to :constrainable, polymorphic: true
  belongs_to :constraint

  delegate :type, :category, :type_code, to: :constraint

  def dataset
    data&.pluck("dataset")
  end

  def entities
    data&.pluck("name", "entity")
  end

  def added?
    true
  end
end
