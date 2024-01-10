# frozen_string_literal: true

class OwnershipCertificateValidationRequest < ValidationRequest
  validates :reason, presence: true
  validates :rejection_reason, presence: true, if: :rejected?
  validates :cancel_reason, presence: true, if: :cancelled?
  validate :allows_only_one_open_ownership_certificate_change, on: :create

  def update_planning_application!(params)
    planning_application.update(valid_ownership_certificate: true)

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

  def rejected?
    approved == false
  end

  def allows_only_one_open_ownership_certificate_change
    return if planning_application.nil?
    return unless planning_application.ownership_certificate_validation_requests.open.any?

    errors.add(:base, "An ownership certificate change request already exists for this planning application.")
  end
end
