# frozen_string_literal: true

class OtherChangeValidationRequest < ApplicationRecord
  include AuditableModel

  include ValidationRequest

  belongs_to :planning_application
  belongs_to :user

  delegate :audits, to: :planning_application

  validates :summary, presence: true
  validates :suggestion, presence: true

  validate :response_is_present?

  def response_is_present?
    errors.add(:base, "some suggestion error here") if closed? && response.blank?
  end

  def create_api_audit!
    audit_created!(
      activity_type: "other_change_validation_request_received",
      activity_information: sequence.to_s,
      audit_comment: audit_api_comment
    )
  end

  private

  def audit_api_comment
    { response: response }.to_json
  end
end
