# frozen_string_literal: true

class Audit < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user, optional: true
  belongs_to :api_user, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  scope :by_created_at, -> { order(created_at: :asc) }
  scope :with_user_and_api_user, -> { preload(:user, :api_user) }
  scope :with_planning_application, -> { includes(:planning_application).where.not(planning_applications: {status: "pending"}) }
  scope :not_by_assigned_officer, lambda {
    joins(:planning_application).where(
      "audits.user_id != planning_applications.user_id OR planning_applications.user_id IS NULL"
    )
  }
  scope :most_recent_for_planning_applications, lambda {
    not_by_assigned_officer.with_planning_application.where(
      created_at: Audit.select("MAX(created_at)").group(:planning_application_id)
    ).reorder(created_at: :desc)
  }

  VALIDATION_REQUEST_ACTIVITY_TYPES = ValidationRequest::REQUEST_TYPES.map(&:underscore).product(%w[cancelled sent received added sent_post_validation cancelled_post_validation]).map { it.join("_").to_sym }.freeze

  enum :activity_type, (%i[
    appeal_decision
    appeal_updated
    approved
    assessed
    assigned
    archived
    unarchived
    submitted
    withdrawn_recommendation
    challenged
    created
    constraint_added
    constraint_removed
    determined
    red_line_created
    red_line_updated
    invalidated
    returned
    updated
    uploaded
    started
    withdrawn
    closed
    deleted
    pre_commencement_condition_validation_request_auto_closed
    red_line_boundary_change_validation_request_auto_closed
    description_change_validation_request_auto_closed
    document_invalidated
    document_changed_to_validated
    document_received_at_changed
    validation_requests_sent
    proposal_measurements_updated
    constraints_checked
    neighbour_letters_sent
    neighbour_letter_copy_mail_sent
    neighbour_response_uploaded
    neighbour_response_edited
    legislation_checked
    pre_application_report_sent
    press_notice
    press_notice_mail
    site_notice_created
    site_notice_not_required
    consultee_emails_sent
    consultee_emails_resent
    consultees_reconsulted
    consultee_response_uploaded
    consultee_response_edited
    committee_details_sent
    sent_to_committee
    review_cil_liability
  ] + VALIDATION_REQUEST_ACTIVITY_TYPES).index_with(&:to_s)

  validates :activity_type, presence: true

  def validation_request
    ValidationRequest.find_by(
      planning_application:,
      sequence: activity_information
    )
  end
end
