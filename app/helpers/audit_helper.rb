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
    when "description_change_request_sent"
      "Sent: request for change (description##{args})"
    when "document_change_request_sent"
      "Sent: request for change (replacement document##{args})"
    when "document_create_request_sent"
      "Sent: request for change (new document##{args})"
    when "red_line_boundary_change_request_sent"
      "Sent: request for change (red line boundary##{args})"
    when "description_change_request_received"
      "Received: request for change (description##{args})"
    when "red_line_boundary_change_request_received"
      "Received: request for change (red line boundary##{args})"
    when "document_change_request_received"
      "Received: request for change (replacement document##{args})"
    when "document_create_request_received"
      "Received: request for change (new document##{args})"
    end
  end

  def define_api_user(audit)
    change_requests = %w[description_change_request_received red_line_boundary_change_request_received document_change_request_received document_create_request_received]
    change_requests.include?(audit.activity_type) ? "Applicant / Agent via #{audit.api_user.name}" : audit.api_user.name
  end
end
