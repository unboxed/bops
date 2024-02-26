# frozen_string_literal: true

class HeadsOfTermsValidationRequest < ValidationRequest
  validate :rejected_reason_is_present?
  validates :cancel_reason, presence: true, if: :cancelled?

  private

  def rejected_reason_is_present?
    return if planning_application.nil?
    return unless approved == false && rejection_reason.blank?

    errors.add(:base,
      "Please include a comment for the case officer to " \
      "indicate why the Heads of terms have been rejected.")
  end

  def audit_api_comment
    if approved?
      {response: "approved"}.to_json
    else
      {response: "rejected", reason: rejection_reason}.to_json
    end
  end

  def audit_comment
    {created_at:}.to_json
  end
end
