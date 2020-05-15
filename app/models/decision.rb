# frozen_string_literal: true

class Decision < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user

  enum status: { pending: 0, granted: 1, refused: 2 }

  validates :status, inclusion: { in: ["granted", "refused"] }

  def mark_granted
    update(status: :granted, decided_at: Time.current)
  end

  def mark_refused
    update(status: :refused, decided_at: Time.current)
  end
end
