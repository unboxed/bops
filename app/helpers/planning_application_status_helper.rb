# frozen_string_literal: true

module PlanningApplicationStatusHelper
  def header_options(planning_application_status)
    options = [
      "Application number",
      "Site address",
      "Application type",
      "Expiry date",
      "Days left to expiry",
      "Status"
    ]

    if planning_application_status.eql?("closed")
      options << "Determination date"
      options.delete("Days left to expiry")
    end

    if planning_application_status.eql?("awaiting_determination")
      options << "Recommendation date"
      options.delete("Status")
    end

    options
  end
end
