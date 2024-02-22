# frozen_string_literal: true

class PreCommencementConditionValidationRequest < ValidationRequest
  RESPONSE_TIME_IN_DAYS = 5

  validates :cancel_reason, presence: true, if: :cancelled?
  validate :rejected_reason_is_present?

  belongs_to :condition

  def response_due
    RESPONSE_TIME_IN_DAYS.business_days.after(created_at).to_date
  end

  private

  def audit_comment
    {
      reason: "Pre-commencement conditions sent to applicant"
    }.to_json
  end

  def audit_api_comment
    if approved?
      {response: "approved"}.to_json
    else
      {response: "rejected", reason: rejection_reason}.to_json
    end
  end

  def rejected_reason_is_present?
    return if planning_application.nil?
    return unless planning_application.invalidated?
    return unless approved == false && rejection_reason.blank?

    errors.add(:base,
      "Please include a comment for the case officer to " \
      "indicate why the pre-commencement condition has been rejected.")
  end
end
