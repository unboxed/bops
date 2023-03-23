# frozen_string_literal: true

module AuditHelper
  def activity(type_of_activity, args = nil)
    case type_of_activity

    when "assigned"
      args.blank? ? "Application unassigned" : "Application assigned to #{args}"
    when "archived"
      "Document archived"
    when "unarchived"
      "Document unarchived"
    when "approved"
      "Recommendation approved"
    when "assessed"
      "Recommendation assessed"
    when "submitted"
      "Recommendation submitted"
    when "withdrawn_recommendation"
      "Recommendation withdrawn"
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
    when "red_line_created"
      "Red line drawing created"
    when "red_line_updated"
      "Red line drawing updated"
    when "document_received_at_changed"
      "#{args} received at date was modified"
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
    when "closed"
      "Application closed"
    when "description_change_validation_request_sent"
      "Sent: description change request (description##{args})"
    when "description_change_request_cancelled"
      "Cancelled: description change request (description##{args})"
    when "replacement_document_validation_request_sent"
      "Sent: validation request (replacement document##{args})"
    when "replacement_document_validation_request_sent_post_validation"
      "Sent: Post-validation request (replacement document##{args})"
    when "additional_document_validation_request_sent"
      "Sent: validation request (new document##{args})"
    when "additional_document_validation_request_sent_post_validation"
      "Sent: Post validation request (new document##{args})"
    when "red_line_boundary_change_validation_request_sent"
      "Sent: validation request (red line boundary##{args})"
    when "red_line_boundary_change_validation_request_sent_post_validation"
      "Sent: Post-validation request (red line boundary##{args})"
    when "replacement_document_validation_request_added"
      "Added: validation request (replacement document##{args})"
    when "additional_document_validation_request_added"
      "Added: validation request (new document##{args})"
    when "red_line_boundary_change_validation_request_added"
      "Added: validation request (red line boundary##{args})"
    when "description_change_validation_request_received"
      "Received: request for change (description##{args})"
    when "red_line_boundary_change_validation_request_received"
      "Received: request for change (red line boundary##{args})"
    when "replacement_document_validation_request_received"
      "Received: request for change (replacement document##{args})"
    when "additional_document_validation_request_received"
      "Received: request for change (new document##{args})"
    when "other_change_validation_request_added"
      "Added: validation request (other validation##{args})"
    when "other_change_validation_request_sent"
      "Sent: validation request (other validation##{args})"
    when "other_change_validation_request_received"
      "Received: request for change (other validation##{args})"
    when "validation_requests_sent"
      "The following invalidation requests have been emailed: #{args}"
    when "additional_document_validation_request_cancelled"
      "Cancelled: validation request (new document##{args})"
    when "additional_document_validation_request_cancelled_post_validation"
      "Cancelled: Post-validation request (new document##{args})"
    when "description_change_validation_request_cancelled"
      "Cancelled: validation request (applicant approval for description change ##{args})"
    when "other_change_validation_request_cancelled"
      "Cancelled: validation request (other change from applicant##{args})"
    when "red_line_boundary_change_validation_request_cancelled"
      "Cancelled: validation request (applicant approval for red line boundary change##{args})"
    when "red_line_boundary_change_validation_request_cancelled_post_validation"
      "Cancelled: Post-validation request (red line boundary##{args})"
    when "replacement_document_validation_request_cancelled"
      "Cancelled: validation request (replace document##{args})"
    when "constraints_checked"
      "Constraints Checked"
    else
      raise ArgumentError, "Activity type: #{type_of_activity} is not valid"
    end
  end

  def audit_user_name(audit)
    if applicant_activity_types.include?(audit.activity_type)
      t("audit_user_name.bops_applicants")
    elsif audit.api_user.present?
      audit_api_user_name(audit)
    elsif audit.user.present?
      audit.user.name
    elsif audit.automated_activity?
      t("audit_user_name.system")
    else
      t("audit_user_name.deleted")
    end
  end

  def audit_api_user_name(audit)
    if applicant_activity_types.include?(audit.activity_type)
      t("audit_user_name.applicant", api_user_name: audit.api_user.name)
    else
      audit.api_user.name
    end
  end

  def applicant_activity_types
    %w[
      description_change_validation_request_received
      replacement_document_validation_request_received
      additional_document_validation_request_received
      red_line_boundary_change_validation_request_received
      other_change_validation_request_received
    ]
  end

  def audit_entry_template(audit)
    if audit.activity_type.match?("/*_validation_request_cancelled")
      "validation_request_cancelled"
    elsif audit.activity_type.include?("request") ||
          audit.activity_type.include?("document_received_at_changed") ||
          audit.activity_type.include?("submitted")
      audit.activity_type
    else
      "generic_audit_entry"
    end
  end
end
