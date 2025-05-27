# frozen_string_literal: true

class OwnershipCertificateValidationRequest < ValidationRequest
  validates :reason, presence: true
  validates :cancel_reason, presence: true, if: :cancelled?
  validate :allows_only_one_open_ownership_certificate_change, on: :create

  validate if: :applicant_responding? do
    if approved.nil?
      errors.add(:approved, :blank, message: "Tell us whether you agree or disagree with the statement")
    end

    if approved == false && rejection_reason.blank?
      errors.add(:rejection_reason, :blank, message: "Tell us why you disagree with the statement")
    end
  end

  after_update do
    if approved_changed? && owner.planning_application.post_validation?
      owner.current_review.update!(status: "in_progress")
    end
  end

  store_accessor :specific_attributes, :old_ownership_certificate
  store_accessor :specific_attributes, :ownership_certificate_submitted

  def ownership_certificate_submitted?
    rejected? || !!ownership_certificate_submitted
  end

  def update_planning_application!(params)
    planning_application.update!(valid_ownership_certificate: true)

    OwnershipCertificateCreationService.new(
      params: params[:params], planning_application:
    ).call
  end

  private

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
