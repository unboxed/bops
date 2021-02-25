# frozen_string_literal: true

module AuditHelper
  def activity(type_of_activity, *args)
    case type_of_activity

    when "assigned"
      args[0].blank? ? "Application unassigned" : "Application assigned to #{args[0]}"
    when "archived"
      "Document archived"
    when "approved"
      "Recommendation approved"
    when "assessed"
      "Recommendation submitted"
    when "challenged"
      "Recommendation challenged"
    when "created"
      "Application created"
    when "determined"
      "Decision Published"
    when "invalidated"
      "Application invalidated"
    when "returned"
      "Application returned"
    when "uploaded"
      "Document uploaded"
    when "started"
      "Application validated"
    when "withdrawn"
      "Application withdrawn"
    end
  end
end
