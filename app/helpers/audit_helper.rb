# frozen_string_literal: true

module AuditHelper
  def activity(type_of_activity, args = {})
    case type_of_activity
      when "assigned"
        [args.gsub(/[^a-zA-Z0-9\-]/," ").present? ? "Application assigned to #{args.gsub(/[^a-zA-Z0-9\-]/," ")}" : "Application unassigned"]
      when "archived"
        ["Document archived", args ]
      when "assessed"
        "Application approved \n\n #{args.gsub(/[^a-zA-Z0-9\-]/," ")}"
      when "challenged"
        "Application challenged \n #{args.gsub(/[^a-zA-Z0-9\-]/," ")}"
      when "created"
        "Application created"
      when "determined"
        "Application determined"
      when "invalidated"
        "Assessment invalidated"
      when "returned"
        "Application returned"
      when "uploaded"
        ["Document uploaded", JSON.parse(args)["filename"]]
      when "started"
        "Application validated"
      when "withdrawn"
        "Application withdrawn \n #{args.gsub(/[^a-zA-Z0-9\-]/," ")}"
    end
  end
end
