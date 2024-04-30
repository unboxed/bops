# frozen_string_literal: true

class SiteVisit < ApplicationRecord
  include DateValidateable

  belongs_to :created_by, class_name: "User"
  belongs_to :consultation
  belongs_to :neighbour, optional: true

  has_many :documents, as: :owner, dependent: :destroy, autosave: true

  validates :status, :comment, presence: true,
    if: -> { decision? && consultation_start_date_present? }
  validates :decision, inclusion: {in: [true, false]}

  validate :consultation_started?, on: :create

  validates :visited_at,
    presence: true,
    date: {
      on_or_before: :current,
      on_or_after: :consultation_start_date
    },
    if: -> { decision? && consultation_start_date_present? }

  enum status: {
    not_started: "not_started",
    complete: "complete"
  }

  scope :by_created_at_desc, -> { order(created_at: :desc) }

  delegate :planning_application, to: :consultation
  delegate :start_date, to: :consultation, prefix: true

  def documents=(files)
    files.select(&:present?).each do |file|
      documents.new(file: file, planning_application: planning_application, tags: %w[internal.siteVisit])
    end
  end

  private

  def consultation_start_date_present?
    consultation&.start_date&.present?
  end

  def consultation_started?
    errors.add(:base, "Start the consultation before creating a site visit") unless consultation_start_date_present?
  end
end
