# frozen_string_literal: true

class OtherChangeValidationRequest < ApplicationRecord
  include ValidationRequest

  belongs_to :planning_application
  belongs_to :user

  validates :summary, presence: true
  validates :suggestion, presence: true

  validate :response_is_present?
  after_create :create_audit!

  def response_is_present?
    errors.add(:base, "some suggestion error here") if closed? && response.blank?
  end

  private

  def audit_api_comment
    { response: response }.to_json
  end

  def create_audit!
    event = planning_application.invalidated? ? "sent" : "added"
    create_audit_for!(event)
  end

  def create_audit_for!(event)
    audit_created!(
      activity_type: "other_change_validation_request_#{event}",
      activity_information: sequence.to_s,
      audit_comment: audit_comment
    )
  end

  def audit_comment
    { summary: summary,
      suggestion: suggestion }.to_json
  end
end
