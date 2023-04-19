# frozen_string_literal: true

class ReviewImmunityDetail < ApplicationRecord
  DECISIONS = %w[Yes No].freeze

  belongs_to :immunity_detail

  with_options class_name: "User", optional: true do
    belongs_to :assessor
    belongs_to :reviewer
  end

  with_options presence: true do
    validates :decision, :decision_reason
    validates :summary, if: :decision_is_immune?
  end

  validates :decision, inclusion: { in: DECISIONS }

  scope :not_accepted, ->() { where(accepted: false).order(created_at: :asc) }

  def decision_is_immune?
    decision == "Yes"
  end
end
