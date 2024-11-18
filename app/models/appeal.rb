# frozen_string_literal: true

class Appeal < ApplicationRecord
  include Auditable
  include DateValidateable

  belongs_to :planning_application

  validates :reason, presence: true
  validates :lodged_at, presence: true,
    date: {
      on_or_before: :current
    }

  has_many :documents, as: :owner, dependent: :destroy, autosave: true

  enum :decision, {allowed: "allowed", dismissed: "dismissed", split_decision: "split_decision", withdrawn: "withdrawn"}

  delegate :audits, to: :planning_application

  after_create :audit_status_update!
  after_update :audit_update!

  with_options on: :mark_as_valid do
    validates :validated_at, presence: true,
      date: {
        on_or_before: :current,
        on_or_after: :lodged_at
      }
  end

  with_options on: :start do
    validates :started_at, presence: true,
      date: {
        on_or_before: :current,
        on_or_after: :validated_at
      }
  end

  with_options on: :determine do
    validates :decision, presence: true
    validates :determined_at, presence: true,
      date: {
        on_or_before: :current,
        on_or_after: :started_at
      }
  end

  include AASM

  aasm.attribute_name :status

  aasm whiny_persistence: true, no_direct_assignment: true do
    state :lodged, initial: true
    state :validated, display: "valid"
    state :started
    state :determined

    event :mark_as_valid do
      transitions from: :lodged, to: :validated
    end

    event :start do
      transitions from: :validated, to: :started
    end

    event :determine do
      transitions from: :started, to: :determined
    end
  end

  class << self
    def statuses
      Appeal.aasm.states.map(&:name)
    end
  end

  def documents=(files)
    files.select(&:present?).each do |file|
      documents.new(file:, planning_application:, tags: document_tags)
    end
  end

  def display_status
    if determined?
      "Appeal #{decision.humanize.downcase}"
    else
      "Appeal #{aasm.human_state.downcase}"
    end
  end

  private

  def document_tags
    if decision?
      %w[internal.appealDecision]
    else
      %w[internal.appeal]
    end
  end

  def audit_update!
    audit_status_update! if saved_change_to_attribute?("status")
    audit_decision_update! if saved_change_to_attribute?("decision")
  end

  def audit_status_update!
    audit!(
      activity_type: "appeal_updated",
      audit_comment: "Appeal status was updated to #{status} on #{(send(:"#{status}_at") || Time.current).to_date.to_fs}"
    )
  end

  def audit_decision_update!
    audit!(
      activity_type: "appeal_decision",
      audit_comment: "Appeal decision was updated to #{decision.humanize.downcase} on #{determined_at.to_date.to_fs}"
    )
  end
end
