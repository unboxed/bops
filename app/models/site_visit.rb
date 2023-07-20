# frozen_string_literal: true

class SiteVisit < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :consultation
  has_many :documents, dependent: :destroy

  validates :status, :comment, presence: true
  validates :decision, inclusion: { in: [true, false] }

  enum status: {
    not_started: "not_started",
    complete: "complete"
  }

  scope :by_created_at_desc, -> { order(created_at: :desc) }

  accepts_nested_attributes_for :documents
end
