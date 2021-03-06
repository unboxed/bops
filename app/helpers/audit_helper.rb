# frozen_string_literal: true

module AuditHelper
  def activity(type_of_activity, args = nil)
    case type_of_activity

    when "assigned"
      args.blank? ? "Application unassigned" : "Application assigned to #{args}"
    when "archived"
      "Document archived"
    when "approved"
      "Recommendation approved"
    when "assessed"
      "Recommendation submitted"
    when "challenged"
      "Recommendation challenged"
    when "created"
      "Application created by #{args}"
    when "constraint_added"
      "Constraint added"
    when "constraint_removed"
      "Constraint removed"
    when "determined"
      "Decision Published"
    when "document_invalidated"
      "#{args} was marked as invalid"
    when "document_changed_to_validated"
      "#{args} was modified from invalid to valid"
    when "invalidated"
      "Application invalidated"
    when "returned"
      "Application returned"
    when "updated"
      "#{args} updated"
    when "uploaded"
      "Document uploaded"
    when "started"
      "Application validated"
    when "withdrawn"
      "Application withdrawn"
    when "description_change_validation_request_sent"
      "Sent: validation request (description##{args})"
    when "replacement_document_validation_request_sent"
      "Sent: validation request (replacement document##{args})"
    when "additional_document_validation_request_sent"
      "Sent: validation request (new document##{args})"
    when "red_line_boundary_change_validation_request_sent"
      "Sent: validation request (red line boundary##{args})"
    when "description_change_validation_request_received"
      "Received: request for change (description##{args})"
    when "red_line_boundary_change_validation_request_received"
      "Received: request for change (red line boundary##{args})"
    when "replacement_document_validation_request_received"
      "Received: request for change (replacement document##{args})"
    when "additional_document_validation_request_received"
      "Received: request for change (new document##{args})"
    when "other_change_validation_request_sent"
      "Sent: validation request (other validation##{args})"
    when "other_change_validation_request_received"
      "Received: request for change (other validation##{args})"
    end
  end

  def define_user(audit)
    audit.activity_type.include?("received") ? "Applicant / Agent via #{audit.api_user.name}" : audit.api_user.name
  end
end
