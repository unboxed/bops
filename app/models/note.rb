# frozen_string_literal: true

class Note < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user

  validates :entry, presence: true, length: { maximum: 500 }

  scope :by_created_at_desc, -> { order(created_at: :desc) }
end
