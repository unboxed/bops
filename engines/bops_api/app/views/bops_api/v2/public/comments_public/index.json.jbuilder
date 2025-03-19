# frozen_string_literal: true

json.partial! "bops_api/v2/shared/postsubmissionApplication/pagination"

json.summary do
  json.partial! "bops_api/v2/shared/postsubmissionApplication/comments/comment_public_summary", total_responses: @total_responses, response_summary: @response_summary
end

json.comments @comments do |comment|
  json.partial! "bops_api/v2/shared/postsubmissionApplication/comments/comment_public", comment:
end
