# frozen_string_literal: true

class PlanningApplicationDrop < ApplicationDrop
  with_options to: :@model do
    delegate :decision
    delegate :reference
  end

  def determined
    @model.determined?
  end

  def granted
    @model.granted?
  end

  def not_required
    @model.not_required?
  end

  def refused
    @model.refused?
  end
end
