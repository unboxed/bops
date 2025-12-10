# frozen_string_literal: true

class Meeting < ApplicationRecord
  include DateValidateable

  belongs_to :created_by, class_name: "User"

  belongs_to :planning_application

  validates :status, presence: true

  validates :occurred_at,
    presence: true,
    date: {
      on_or_before: :current
    }

  enum :status, %i[
    not_started
    complete
  ].index_with(&:to_s)

  scope :by_created_at_desc, -> { order(created_at: :desc) }
  scope :by_occurred_at_desc, -> { order(occurred_at: :desc, created_at: :desc) }
end
