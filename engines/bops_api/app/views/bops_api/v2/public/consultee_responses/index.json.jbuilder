# frozen_string_literal: true

json.partial! "bops_api/v2/shared/postsubmissionApplication/pagination"

json.summary do
  json.partial!(
    "bops_api/v2/shared/postsubmissionApplication/comments/comment_specialist_summary",
    total_comments: @total_comments,
    total_consulted: @total_consulted,
    response_summary: @response_summary
  )
end

json.comments @comments do |comment|
  json.partial! "bops_api/v2/shared/postsubmissionApplication/comments/comment_specialist", comment: comment
end
