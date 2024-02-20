# frozen_string_literal: true

class PreCommencementConditionValidationRequest < ValidationRequest
  validates :cancel_reason, presence: true, if: :cancelled?

  has_one :condition

  private

  def audit_comment
    {
      reason: "Pre-commencement conditions sent to applicant"
    }.to_json
  end
end
