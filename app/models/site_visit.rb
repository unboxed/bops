# frozen_string_literal: true

class SiteVisit < ApplicationRecord
  include DateValidateable

  belongs_to :created_by, class_name: "User"

  belongs_to :neighbour, optional: true
  belongs_to :planning_application

  has_many :documents, as: :owner, dependent: :destroy, autosave: true

  validates :status, :comment, presence: true, if: -> { decision? }
  validates :decision, inclusion: {in: [true, false]}

  validates :visited_at,
    presence: true,
    date: {
      on_or_before: :current
    },
    if: -> { decision? }

  enum :status, %i[
    not_started
    complete
  ].index_with(&:to_s)

  scope :by_created_at_desc, -> { order(created_at: :desc) }

  delegate :consultation, to: :planning_application, allow_nil: true

  def documents=(files)
    files.select(&:present?).each do |file|
      documents.new(file: file, planning_application: planning_application, tags: %w[internal.siteVisit])
    end
  end

  def address
    super || neighbour.try(:address)
  end
end
