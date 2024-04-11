# frozen_string_literal: true

class PressNotice < ApplicationRecord
  class NotCreatableError < StandardError; end

  include Auditable
  include DateValidateable
  include Consultable

  REASONS = %i[
    conservation_area
    listed_building
    major_development
    wildlife_and_countryside
    development_plan
    environment
    ancient_monument
    public_interest
    other
  ].freeze

  belongs_to :planning_application
  has_many :documents, as: :owner, dependent: :destroy, autosave: true

  validates :required, inclusion: {in: [true, false]}

  with_options presence: true do
    validates :reasons, if: :required?
    validates :other_reason, if: :other_selected?
  end

  with_options on: :confirmation do
    validates :published_at,
      date: {
        on_or_before: :current,
        on_or_after: :consultation_start_date
      }
  end

  before_validation :reset_reasons, unless: :required?
  before_validation :reset_other_reason, unless: :other_selected?
  before_create :ensure_publicity_feature!

  after_update :extend_consultation!, if: :saved_change_to_published_at?
  after_save :audit_press_notice!, if: :audit_required?

  delegate :audits, to: :planning_application
  delegate :local_authority, to: :planning_application
  delegate :press_notice_email, to: :local_authority

  scope :required, -> { where(required: true) }

  alias_method :consultable_event_at, :published_at

  def reason
    ((reasons - %w[other]) + [other_reason]).compact.to_sentence.humanize
  end

  def reasons
    Array.wrap(super)
  end

  def reasons=(values)
    super(Array.wrap(values).compact_blank)
  end

  def other_selected?
    reasons.include?("other")
  end

  def documents=(files)
    files.select(&:present?).each do |file|
      documents.new(file: file, planning_application: planning_application, tags: %w[internal.pressNotice])
    end
  end

  def incomplete?
    required? && !published_at?
  end

  def complete?
    !incomplete?
  end

  def last_document
    @last_document ||= documents.preload(:user).order(created_at: :desc).first
  end

  def uploaded_by
    last_document&.user
  end

  private

  def reset_reasons
    self.reasons = []
  end

  def reset_other_reason
    self.other_reason = nil
  end

  def audit_required?
    saved_change_to_required? || saved_change_to_reasons?
  end

  def audit_comment
    if required?
      "Press notice has been marked as required with the following reasons: #{reasons.join(", ")}"
    else
      "Press notice has been marked as not required"
    end
  end

  def audit_press_notice!
    audit!(activity_type: "press_notice", audit_comment: audit_comment)
  end

  def ensure_publicity_feature!
    return if planning_application.publicity_consultation_feature?

    raise NotCreatableError,
      "Cannot create press notice when application type does not permit this feature."
  end
end
