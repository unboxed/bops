# frozen_string_literal: true

class OtherChangeValidationRequest < ValidationRequest
  validates :reason, presence: true
  validates :suggestion, presence: true
  validates :cancel_reason, presence: true, if: :cancelled?

  before_create :ensure_planning_application_not_validated!

  def ensure_planning_application_not_validated!
    return unless planning_application_validated?

    raise ValidationRequestNotCreatableError,
      "Cannot create #{type.titleize} when planning application has been validated"
  end

  private

  def audit_api_comment
    {applicant_response:}.to_json
  end

  def audit_comment
    {reason:,
     suggestion:}.to_json
  end
end
