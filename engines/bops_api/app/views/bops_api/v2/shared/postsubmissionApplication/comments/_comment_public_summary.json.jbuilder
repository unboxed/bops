# frozen_string_literal: true

json.totalComments total_responses
if response_summary.present?
  json.sentiment do
    json.supportive response_summary[:supportive]
    json.objection response_summary[:objection]
    json.neutral response_summary[:neutral]
  end
end
