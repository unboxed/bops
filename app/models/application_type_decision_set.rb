# frozen_string_literal: true

class ApplicationTypeDecisionSet
  include StoreModel::Model

  DECISIONS = %w[granted granted_not_required refused].freeze

  attribute :decisions, :list, default: -> { [] }

  validates :decisions, presence: true, on: :decision_set
end
