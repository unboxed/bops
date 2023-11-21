# frozen_string_literal: true

class OwnershipCertificateValidationRequest < ValidationRequest
  validates :reason, presence: true
  validates :suggestion, presence: true
  validate :rejected_reason_is_present?
  validates :cancel_reason, presence: true, if: :cancelled?
  validate :allows_only_one_open_ownership_certificate_change, on: :create

  private

  def rejected_reason_is_present?
    return if planning_application.nil?
    return unless planning_application.invalidated?
    return unless approved == false && rejection_reason.blank?

    errors.add(:base,
      "Please include a comment for the case officer to " \
      "indicate why the ownership certificate change has been rejected.")
  end

  def audit_api_comment
    if approved?
      {response: "approved"}.to_json
    else
      {response: "rejected", reason: rejection_reason}.to_json
    end
  end

  def audit_comment
    reason
  end

  def allows_only_one_open_ownership_certificate_change
    return if planning_application.nil?
    return unless planning_application.ownership_certificate_validation_requests.open.any?

    errors.add(:base, "An ownership certificate change request already exists for this planning application.")
  end
end
