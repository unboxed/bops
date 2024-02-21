# frozen_string_literal: true

class PreCommencementConditionValidationRequest < ValidationRequest
  RESPONSE_TIME_IN_DAYS = 5

  validates :cancel_reason, presence: true, if: :cancelled?

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
end
