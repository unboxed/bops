# frozen_string_literal: true

class TimeExtensionValidationRequest < ValidationRequest
  validates :proposed_expiry_date, presence: true
  validates :cancel_reason, presence: true, if: :cancelled?
  validates :reason, presence: true
  validate :rejected_reason_is_present?
  validate :allows_only_one_open_time_extension, on: :create
  validate :proposed_expiry_is_later?

  validate if: :applicant_responding? do
    if approved.nil?
      errors.add(:approved, :blank, message: "Tell us whether you agree or disagree with the change")
    end

    if approved == false && rejection_reason.blank?
      errors.add(:rejection_reason, :blank, message: "Tell us why you disagree with the change")
    end
  end

  def proposed_expiry_is_later?
    return if planning_application.nil? || proposed_expiry_date.blank?

    if proposed_expiry_date < planning_application.expiry_date
      errors.add(:proposed_expiry_date, "must be later than existing expiry date")
    end
  end

  def allows_only_one_open_time_extension
    return if planning_application.nil?
    return unless planning_application.time_extension_validation_requests.open.any?

    errors.add(:base, "An open time extension request already exists for this planning application.")
  end

  def rejected_reason_is_present?
    return if planning_application.nil?
    return unless approved == false && rejection_reason.blank?

    errors.add(:base,
      "Please include a comment for the case officer to " \
      "indicate why the time extension request has been rejected.")
  end

  def audit_comment
    {
      previous: planning_application.expiry_date,
      proposed: proposed_expiry_date
    }.to_json
  end

  def audit_api_comment
    {response:}.to_json
  end

  def email_and_timestamp
    send_validation_request_email
    mark_as_sent!
  end

  def previous_expiry_date
    super&.to_date
  end

  def update_planning_application!(*)
    self.previous_expiry_date = planning_application.expiry_date
    save!(validate: false)

    modified_target_date = proposed_expiry_date - 19.days
    planning_application.update_columns(expiry_date: proposed_expiry_date, target_date: modified_target_date)
  end
end
