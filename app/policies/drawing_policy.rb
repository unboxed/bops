# frozen_string_literal: true

class DrawingPolicy < ApplicationPolicy
  self.editors = %w[assessor reviewer admin]
end
