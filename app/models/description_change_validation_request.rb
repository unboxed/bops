# frozen_string_literal: true

class DescriptionChangeValidationRequest < ApplicationRecord
  include ValidationRequest

  before_create :set_previous_application_description

  belongs_to :planning_application
  belongs_to :user

  validates :proposed_description, presence: true
  validate :rejected_reason_is_present?
  validate :allows_only_one_open_description_change, on: :create
  validate :planning_application_has_not_been_determined, on: :create
  after_create :create_audit!

  scope :open_change_created_over_5_business_days_ago, -> { open.where("created_at <= ?", 5.business_days.ago) }
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

  def request_expiry_date
    5.business_days.after(created_at)
  end

  def rejected?
    !approved && rejection_reason.present?
  end

  private

  def audit_api_comment
    if approved?
      { response: "approved" }.to_json
    else
      { response: "rejected", reason: rejection_reason }.to_json
    end
  end

  def create_audit!
    audit_created!(
      activity_type: "description_change_validation_request_sent",
      activity_information: sequence.to_s,
      audit_comment: audit_comment
    )
  end

  def audit_comment
    { previous: planning_application.description,
      proposed: proposed_description }.to_json
  end
end
