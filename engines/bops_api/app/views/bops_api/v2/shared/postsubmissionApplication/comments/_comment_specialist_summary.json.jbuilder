# frozen_string_literal: true

json.totalConsulted total_consulted
json.totalComments total_comments
if response_summary.present?
  json.sentiment do
    json.approved response_summary[:approved]
    json.amendmentsNeeded response_summary[:amendments_needed]
    json.objected response_summary[:objected]
  end
end
