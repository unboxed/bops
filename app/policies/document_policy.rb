# frozen_string_literal: true

class DocumentPolicy < ApplicationPolicy
  self.editors = %w[assessor reviewer]
end
