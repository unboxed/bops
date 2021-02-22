# frozen_string_literal: true

module AuditHelper
  def activity(type_of_activity, *user)
    case type_of_activity
      when "assigned"
        "Application assigned to #{user}"
      when "archived"
        "Document archived"
      when "assessed"
        "Application approved"
      when "challenged"
        "Assessment challenged"
      when "created"
        "Application created"
      when "determined"
        "Application determined"
      when "invalidated"
        "Assessment invalidated"
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
