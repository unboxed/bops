# frozen_string_literal: true

# NOTE: you must switch to the applicants steps before using these
# steps; see e2e_steps.rb

Given("I look at the validation requests on my application") do
  qs = format(
    "planning_application_id=%s&change_access_id=%s",
    @planning_application.id,
    @planning_application.change_access_id
  )

  visit "/validation_requests/?#{qs}"
end
