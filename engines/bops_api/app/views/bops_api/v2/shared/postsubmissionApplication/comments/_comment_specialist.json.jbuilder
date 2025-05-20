# frozen_string_literal: true

# DprComment

json.id comment.id
json.sentiment comment.summary_tag.camelize(:lower)
json.comment comment.redacted_response
json.receivedAt format_postsubmission_datetime(comment.received_at)

# SpecialistComment

# json.id comment.id
# json.sentiment comment.summary_tag
# json.comment comment.redacted_response
# json.constraints "PlanningConstraint[]"
# json.reason "string"
# json.comment "string"
# json.author "SpecialistCommentAuthor"
# json.consultedAt "DateTime"
# json.respondedAt "DateTime"
# json.files "PostSubmissionFile[]"
# json.responses "SpecialistComment[]"

# json.author do
#   json.name do
#     json.singleLine comment.name
#   end
# #   json.organisation "string;"
# #   json.specialism "string;"
# #   json.jobTitle "string;"
# end

# json.metadata do
#   json.submittedAt format_postsubmission_datetime(comment.created_at)
#   # json.publishedAt format_postsubmission_datetime(comment.received_at)
#   json.validAt format_postsubmission_datetime(comment.updated_at)
# end
