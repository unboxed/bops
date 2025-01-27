# frozen_string_literal: true

json.key_format! camelize: :lower


  if (consultation = planning_application.consultation)
    json.consultation do

      json.publishedComments planning_application.consultation.neighbour_responses.redacted do |response|
        json.comment response.redacted_response
        json.receivedAt response.received_at
        json.summaryTag response.summary_tag
      end

      json.consulteeComments planning_application.consultation.consultee_responses.redacted do |response|
        json.comment response.redacted_response
        json.receivedAt response.received_at
      end
    end
  end
end

