# frozen_string_literal: true

class DescriptionChangeValidationRequest < ValidationRequest
  RESPONSE_TIME_IN_DAYS = 5

  validates :proposed_description, presence: true
  validate :allows_only_one_open_description_change, on: :create
  validate :planning_application_has_not_been_determined, on: :create
  validate :rejected_reason_is_present?

  before_create :set_previous_application_description

  def response_due
    RESPONSE_TIME_IN_DAYS.business_days.after(created_at).to_date
  end

  def update_planning_application!(params)
    planning_application.update!(description: proposed_description)
  end

  private

  def create_audit!
    create_audit_for!("sent")
  end

  def email_and_timestamp
    send_description_request_email

    mark_as_sent!
  end

  def audit_comment
    {
      previous: planning_application.description,
      proposed: proposed_description
    }.to_json
  end

  def allows_only_one_open_description_change
    return if planning_application.nil?
    return unless planning_application.description_change_validation_requests.open.any?

    errors.add(:base, "An open description change already exists for this planning application.")
  end

  def planning_application_has_not_been_determined
    return if planning_application.nil?
    return unless planning_application.determined?

    errors.add(:base, "A description change request cannot be submitted for a determined planning application.")
  end

  def rejected_reason_is_present?
    return if planning_application.nil?
    return unless approved == false && rejection_reason.blank?

    errors.add(:base,
      "Please include a comment for the case officer to " \
      "indicate why the red line boundary change has been rejected.")
  end

  def set_previous_application_description
    self.previous_description = planning_application.description
  end

  def audit_api_comment
    if approved?
      {response: "approved"}.to_json
    else
      {response: "rejected", reason: rejection_reason}.to_json
    end
  end

  def update_planning_application_for_auto_closed_request!
    planning_application.update!(description: proposed_description)
  end
end
