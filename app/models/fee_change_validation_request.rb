# frozen_string_literal: true

class FeeChangeValidationRequest < ValidationRequest
  validates :reason, presence: true
  validates :suggestion, presence: true
  validate :ensure_no_open_or_pending_fee_item_validation_request, on: :create
  validates :cancel_reason, presence: true, if: :cancelled?

  before_create :ensure_planning_application_not_validated!
  after_create :set_invalid_payment_amount
  before_update :reset_fee_invalidation, if: :closed?
  before_destroy :reset_fee_invalidation

  before_create lambda {
                  reset_validation_requests_update_counter!(planning_application.validation_requests.fee_changes)
                }

  private

  def audit_comment
    {reason:,
     suggestion:}.to_json
  end

  def ensure_no_open_or_pending_fee_item_validation_request
    return if planning_application.nil?
    return unless planning_application.validation_requests.fee_changes.open_or_pending.any?

    errors.add(:base, "An open or pending fee validation request already exists for this planning application.")
  end

  def ensure_planning_application_not_validated!
    return unless planning_application_validated?

    raise ValidationRequestNotCreatableError,
      "Cannot create #{request_type.titleize} Validation Request when planning application has been validated"
  end

  def set_invalid_payment_amount
    planning_application.update!(invalid_payment_amount: planning_application.payment_amount)
  end

  def reset_fee_invalidation
    transaction do
      planning_application.validation_requests.fee_changes.closed.max_by(&:closed_at)&.update_counter! if cancelled?
      planning_application.update!(valid_fee: nil)
    end
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetFeeInvalidationError, e.message
  end
end
