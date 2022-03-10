# frozen_string_literal: true

class Audit < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user, optional: true
  belongs_to :api_user, optional: true

  scope :by_created_at, -> { order(created_at: :asc) }
  scope :with_user_and_api_user, -> { preload(:user, :api_user) }

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
    auto_closed: "auto_closed",
    document_invalidated: "document_invalidated",
    document_changed_to_validated: "document_changed_to_validated",
    document_received_at_changed: "document_received_at_changed",
    description_change_validation_request_sent: "description_change_validation_request_sent",
    description_change_request_cancelled: "description_change_request_cancelled",
    replacement_document_validation_request_sent: "replacement_document_validation_request_sent",
    additional_document_validation_request_sent: "additional_document_validation_request_sent",
    red_line_boundary_change_validation_request_sent: "red_line_boundary_change_validation_request_sent",
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
    validation_requests_sent: "validation_requests_sent",
    additional_document_validation_request_cancelled: "additional_document_validation_request_cancelled",
    description_change_validation_request_cancelled: "description_change_validation_request_cancelled",
    other_change_validation_request_cancelled: "other_change_validation_request_cancelled",
    red_line_boundary_change_validation_request_cancelled: "red_line_boundary_change_validation_request_cancelled",
    replacement_document_validation_request_cancelled: "replacement_document_validation_request_cancelled",
    constraints_checked: "constraints_checked"
  }

  validates :activity_type, presence: true
end
