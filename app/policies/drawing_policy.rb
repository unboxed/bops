# frozen_string_literal: true

class DrawingPolicy < ApplicationPolicy
  self.viewers = %w[assessor reviewer admin]

  def index?
    super || signed_in_viewer?
  end
end
