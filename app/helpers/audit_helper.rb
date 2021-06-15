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
    end
  end
end
