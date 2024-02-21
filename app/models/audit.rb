# frozen_string_literal: true

class Audit < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user, optional: true
  belongs_to :api_user, optional: true

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

  enum activity_type: {
    approved: "approved",
    assessed: "assessed",
    assigned: "assigned",
    archived: "archived",
    unarchived: "unarchived",
    submitted: "submitted",
    withdrawn_recommendation: "withdrawn_recommendation",
    challenged: "challenged",
    created: "created",
    constraint_added: "constraint_added",
    constraint_removed: "constraint_removed",
    determined: "determined",
    red_line_created: "red_line_created",
    red_line_updated: "red_line_updated",
    invalidated: "invalidated",
    returned: "returned",
    updated: "updated",
    uploaded: "uploaded",
    started: "started",
    withdrawn: "withdrawn",
    closed: "closed",
    pre_commencement_condition_validation_request_sent_post_validation: "pre_commencement_condition_validation_request_sent_post_validation",
    pre_commencement_condition_validation_request_auto_closed: "pre_commencement_condition_validation_request_auto_closed",
    pre_commencement_condition_validation_request_added: "pre_commencement_condition_validation_request_added",
    pre_commencement_condition_validation_request_cancelled_post_validation: "pre_commencement_condition_validation_request_cancelled_post_validation",
    red_line_boundary_change_validation_request_auto_closed: "red_line_boundary_change_validation_request_auto_closed",
    description_change_validation_request_auto_closed: "description_change_validation_request_auto_closed",
    document_invalidated: "document_invalidated",
    document_changed_to_validated: "document_changed_to_validated",
    document_received_at_changed: "document_received_at_changed",
    description_change_validation_request_sent: "description_change_validation_request_sent",
    description_change_validation_request_cancelled: "description_change_validation_request_cancelled",
    description_change_validation_request_added: "description_change_validation_request_added",
    description_change_validation_request_sent_post_validation: "description_change_validation_request_sent_post_validation",
    description_change_validation_request_cancelled_post_validation: "description_change_validation_request_cancelled_post_validation",
    replacement_document_validation_request_sent: "replacement_document_validation_request_sent",
    replacement_document_validation_request_sent_post_validation:
      "replacement_document_validation_request_sent_post_validation",
    additional_document_validation_request_sent: "additional_document_validation_request_sent",
    additional_document_validation_request_sent_post_validation:
      "additional_document_validation_request_sent_post_validation",
    red_line_boundary_change_validation_request_sent: "red_line_boundary_change_validation_request_sent",
    red_line_boundary_change_validation_request_sent_post_validation:
      "red_line_boundary_change_validation_request_sent_post_validation",
    replacement_document_validation_request_added: "replacement_document_validation_request_added",
    additional_document_validation_request_added: "additional_document_validation_request_added",
    red_line_boundary_change_validation_request_added: "red_line_boundary_change_validation_request_added",
    description_change_validation_request_received: "description_change_validation_request_received",
    replacement_document_validation_request_received: "replacement_document_validation_request_received",
    additional_document_validation_request_received: "additional_document_validation_request_received",
    red_line_boundary_change_validation_request_received: "red_line_boundary_change_validation_request_received",
    other_change_validation_request_added: "other_change_validation_request_added",
    other_change_validation_request_sent: "other_change_validation_request_sent",
    other_change_validation_request_received: "other_change_validation_request_received",
    other_change_validation_request_sent_post_validation: "other_change_validation_request_sent_post_validation",
    ownership_certificate_validation_request_added: "ownership_certificate_validation_request_added",
    ownership_certificate_validation_request_received: "ownership_certificate_validation_request_received",
    ownership_certificate_validation_request_sent: "ownership_certificate_validation_request_sent",
    ownership_certificate_validation_request_cancelled: "ownership_certificate_validation_request_cancelled",
    ownership_certificate_validation_request_sent_post_validation: "ownership_certificate_validation_request_sent_post_validation",
    validation_requests_sent: "validation_requests_sent",
    additional_document_validation_request_cancelled: "additional_document_validation_request_cancelled",
    additional_document_validation_request_cancelled_post_validation:
      "additional_document_validation_request_cancelled_post_validation",
    other_change_validation_request_cancelled: "other_change_validation_request_cancelled",
    fee_change_validation_request_cancelled: "fee_change_validation_request_cancelled",
    fee_change_validation_request_added: "fee_change_validation_request_added",
    fee_change_validation_request_sent: "fee_change_validation_request_sent",
    fee_change_validation_request_sent_post_validation: "fee_change_validation_request_sent_post_validation",
    fee_change_validation_request_received: "fee_change_validation_request_received",
    proposal_measurements_updated: "proposal_measurements_updated",
    red_line_boundary_change_validation_request_cancelled: "red_line_boundary_change_validation_request_cancelled",
    red_line_boundary_change_validation_request_cancelled_post_validation:
    "red_line_boundary_change_validation_request_cancelled_post_validation",
    replacement_document_validation_request_cancelled: "replacement_document_validation_request_cancelled",
    replacement_document_validation_request_cancelled_post_validation:
      "replacement_document_validation_request_cancelled_post_validation",
    constraints_checked: "constraints_checked",
    neighbour_letters_sent: "neighbour_letters_sent",
    neighbour_letter_copy_mail_sent: "neighbour_letter_copy_mail_sent",
    neighbour_response_uploaded: "neighbour_response_uploaded",
    neighbour_response_edited: "neighbour_response_edited",
    legislation_checked: "legislation_checked",
    press_notice: "press_notice",
    press_notice_mail: "press_notice_mail",
    site_notice_created: "site_notice_created",
    consultee_emails_sent: "consultee_emails_sent",
    consultee_emails_resent: "consultee_emails_resent",
    consultees_reconsulted: "consultees_reconsulted",
    consultee_response_uploaded: "consultee_response_uploaded",
    consultee_response_edited: "consultee_response_edited"
  }

  validates :activity_type, presence: true

  def validation_request
    ValidationRequest.find_by(
      planning_application:,
      sequence: activity_information
    )
  end
end
