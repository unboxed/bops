# frozen_string_literal: true

json.array! @specialists do |specialist|
  json.id specialist.id.to_s
  json.organisationSpecialism specialist.organisation if specialist.organisation.present?
  json.jobTitle specialist.role if specialist.role.present?
  json.reason specialist.reason

  # Constraints Information
  if specialist.active_constraints.any?
    json.constraints specialist.active_constraints do |planning_app_constraint|
      # Skip if the constraint itself is missing
      next unless planning_app_constraint.constraint
      constraint = planning_app_constraint.constraint

      json.child! do
        json.value constraint.type
        json.category constraint.category
        json.description constraint.type_code
        json.intersects planning_app_constraint.identified?

        # Include entities if present. Only including name for now but will expand to show source
        if planning_app_constraint.data&.any?
          json.entities planning_app_constraint.data do |item|
            json.name item["name"]
          end
        end
      end
    end
  end

  json.firstConsultedAt format_postsubmission_datetime(specialist.email_sent_at) if specialist.email_sent_at
  # Comments
  json.comments specialist.comments do |resp|
    json.id resp.id.to_s
    json.sentiment resp.summary_tag.camelize(:lower)
    json.commentRedacted resp.redacted_response

    if resp.documents.any?
      json.files resp.documents do |document|
        json.partial! "bops_api/v2/shared/document", document: document
      end
    end

    json.metadata do
      json.submittedAt format_postsubmission_datetime(resp.created_at)
      # json.validatedAt format_postsubmission_datetime(resp.redacted_at)
      json.publishedAt format_postsubmission_datetime(resp.updated_at)
    end
  end
end
