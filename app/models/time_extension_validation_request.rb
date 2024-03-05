# frozen_string_literal: true

class TimeExtensionValidationRequest < ValidationRequest

  validates :proposed_expiry_date, presence: true
  validates :reason, presence: true
  validate :allows_only_one_open_time_extension, on: :create
  validate :proposed_expiry_is_later?

  def proposed_expiry_is_later?
    return if proposed_expiry_date.blank?
    if proposed_expiry_date < planning_application.expiry_date
      errors.add(:proposed_expiry_date, 'must be later than existing expiry date')
    end
  end

  def allows_only_one_open_time_extension
    return if planning_application.nil?
    return unless planning_application.time_extension_validation_requests.open.any?

    errors.add(:base, "An open time extension request already exists for this planning application.")
  end

  def audit_comment
    {
      previous: planning_application.expiry_date,
      proposed: proposed_expiry_date
    }.to_json
  end

  def email_and_timestamp
    send_validation_request_email
    mark_as_sent!
  end
end
