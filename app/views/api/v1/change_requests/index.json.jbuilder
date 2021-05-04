# frozen_string_literal: true

json.data @planning_application.description_change_requests.each do |description_change_request|
  json.extract! description_change_request,
                :id,
                :state,
                :response_due,
                :proposed_description,
                :rejection_reason,
                :approved,
                :days_until_response_due
  json.type "description_change_request"
end
