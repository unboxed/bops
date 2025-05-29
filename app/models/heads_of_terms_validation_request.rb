# frozen_string_literal: true

class HeadsOfTermsValidationRequest < ValidationRequest
  belongs_to :owner, polymorphic: true
  delegate :title, :text, to: :owner, prefix: :term, allow_nil: true

  validate :rejected_reason_is_present?
  validates :cancel_reason, presence: true, if: :cancelled?
  validate :allows_only_one_open_heads_of_terms_request, on: :create

  validate if: :applicant_responding? do
    if approved.nil?
      errors.add(:approved, :blank, message: "Tell us whether you agree or disagree with the term")
    end

    if approved == false && rejection_reason.blank?
      errors.add(:rejection_reason, :blank, message: "Tell us why you disagree with the term")
    end
  end

  before_validation :cancel_now!, if: :cancelled?

  private

  def rejected_reason_is_present?
    return if planning_application.nil?
    return unless approved == false && rejection_reason.blank?

    errors.add(:base,
      "Please include a comment for the case officer to " \
      "indicate why the Heads of terms have been rejected.")
  end

  def allows_only_one_open_heads_of_terms_request
    return if planning_application.nil?
    return unless owner.validation_requests.open.any?

    errors.add(:base, "An open request already exists for this term.")
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

  def cancel_now!
    owner.update!(cancelled_at: Time.zone.today)
  end
end
