# frozen_string_literal: true

class OtherChangeValidationRequest < ApplicationRecord
  class ResetFeeInvalidationError < StandardError; end

  include ValidationRequestable

  belongs_to :planning_application
  belongs_to :user

  validates :summary, presence: true
  validates :suggestion, presence: true

  validate :response_is_present?
  validate :ensure_no_open_or_pending_fee_item_validation_request, on: :create

  before_create :ensure_planning_application_not_validated!
  after_create :set_invalid_payment_amount
  before_update :reset_fee_invalidation, if: :closed?
  before_destroy :reset_fee_invalidation

  scope :fee_item, -> { where(fee_item: true) }
  scope :non_fee_item, -> { where(fee_item: false) }

  def response_is_present?
    errors.add(:base, "some suggestion error here") if closed? && response.blank?
  end

  def reset_fee_invalidation
    return unless fee_item?

    planning_application.update!(valid_fee: nil)
  rescue ActiveRecord::ActiveRecordError => e
    raise ResetFeeInvalidationError, e.message
  end

  private

  def audit_api_comment
    { response: response }.to_json
  end

  def audit_comment
    { summary: summary,
      suggestion: suggestion }.to_json
  end

  def ensure_no_open_or_pending_fee_item_validation_request
    return unless fee_item?
    return unless planning_application.fee_item_validation_requests.open_or_pending.any?

    errors.add(:base, "An open or pending fee validation request already exists for this planning application.")
  end

  def set_invalid_payment_amount
    return unless fee_item?

    planning_application.update!(invalid_payment_amount: planning_application.payment_amount)
  end
end
