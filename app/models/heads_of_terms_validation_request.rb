# frozen_string_literal: true

class HeadsOfTermsValidationRequest < ValidationRequest
  RESPONSE_TIME_IN_DAYS = 10

  has_one :document, as: :owner, class_name: "Document", dependent: :destroy

  validates :document, presence: true
  validate :rejected_reason_is_present?
  validates :cancel_reason, presence: true, if: :cancelled?
  validate :allows_only_one_open_heads_of_terms_request, on: :create

  accepts_nested_attributes_for :document

  def response_due
    RESPONSE_TIME_IN_DAYS.business_days.after(created_at).to_date
  end

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

  def allows_only_one_open_heads_of_terms_request
    return if planning_application.nil?
    return unless planning_application.heads_of_terms_validation_requests.open.any?

    errors.add(:base, "A Heads of terms request already exists for this planning application.")
  end
end
