# frozen_string_literal: true

class DescriptionChangeValidationRequest < ApplicationRecord
  include ValidationRequest

  RESPONSE_TIME_IN_DAYS = 5

  before_create :set_previous_application_description

  belongs_to :planning_application
  belongs_to :user

  validates :proposed_description, presence: true
  validate :rejected_reason_is_present?
  validate :allows_only_one_open_description_change, on: :create
  validate :planning_application_has_not_been_determined, on: :create

  scope :responded, -> { closed.where(cancelled_at: nil, auto_closed: false).order(created_at: :asc) }

  def rejected_reason_is_present?
    if approved == false && rejection_reason.blank?
      errors.add(:base,
                 "Please include a comment for the case officer to indicate why the description change has been rejected.")
    end
  end

  def set_previous_application_description
    self.previous_description = planning_application.description
  end

  def allows_only_one_open_description_change
    if planning_application.open_description_change_requests.any?
      errors.add(:base, "An open description change already exists for this planning application.")
    end
  end

  def planning_application_has_not_been_determined
    if planning_application.determined?
      errors.add(:base, "A description change request cannot be submitted for a determined planning application.")
    end
  end

  def rejected?
    !approved && rejection_reason.present?
  end

  # TODO, move this on validation_request on the event cancel
  # in order to do that we need to make a change this activity_type
  # to description_change_validation_request_cancelled, stop audit
  # the user in the audit_comment delete it.
  def audit_cancel!
    audit!(
      activity_type: "description_change_request_cancelled",
      activity_information: sequence,
      audit_comment: Current.user&.name
    )
  end

  def response_due
    RESPONSE_TIME_IN_DAYS.business_days.after(created_at).to_date
  end

  def update_planning_application_for_auto_closed_request!
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

  def audit_api_comment
    if approved?
      { response: "approved" }.to_json
    else
      { response: "rejected", reason: rejection_reason }.to_json
    end
  end

  def audit_comment
    { previous: planning_application.description,
      proposed: proposed_description }.to_json
  end
end
