# frozen_string_literal: true

class ImmunityDetail < ApplicationRecord
  belongs_to :planning_application

  enum(
    status: {
      not_started: "not_started",
      in_progress: "in_progress",
      complete: "complete"
    },
    _default: "not_started"
  )

  validates :status, presence: true
end
