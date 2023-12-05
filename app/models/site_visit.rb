# frozen_string_literal: true

class SiteVisit < ApplicationRecord
  include DateValidateable

  belongs_to :created_by, class_name: "User"
  belongs_to :consultation
  belongs_to :neighbour, optional: true

  has_many :documents, as: :owner, dependent: :destroy, autosave: true

  validates :status, :comment, presence: true
  validates :decision, inclusion: {in: [true, false]}

  validates :visited_at,
    presence: true,
    date: {
      on_or_before: :current,
      on_or_after: :consultation_start_date
    },
    if: :decision?

  enum status: {
    not_started: "not_started",
    complete: "complete"
  }

  scope :by_created_at_desc, -> { order(created_at: :desc) }

  delegate :planning_application, to: :consultation
  delegate :start_date, to: :consultation, prefix: true

  def documents=(files)
    files.select(&:present?).each do |file|
      documents.new(file: file, planning_application: planning_application, tags: ["Site Visit"])
    end
  end
end
