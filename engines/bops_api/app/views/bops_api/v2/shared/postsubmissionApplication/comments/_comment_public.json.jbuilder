# frozen_string_literal: true

# DprComment

json.id comment.id
json.sentiment comment.summary_tag
json.comment comment.redacted_response
json.receivedAt format_postsubmission_datetime(comment.received_at)

# PublicComment

# json.id comment.id
# json.sentiment comment.summary_tag
# json.comment comment.redacted_response

# json.author do
#   json.name do
#     json.singleLine comment.name
#   end
# end

# json.metadata do
#   json.submittedAt format_postsubmission_datetime(comment.created_at)
#   json.publishedAt format_postsubmission_datetime(comment.received_at)
#   json.validAt format_postsubmission_datetime(comment.updated_at)
# end
