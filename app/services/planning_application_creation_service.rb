# frozen_string_literal: true

class PlanningApplicationCreationService
  def initialize(attrs, local_authority:, application_type:)
    @attrs = attrs.with_indifferent_access
    @local_authority = local_authority
    @application_type = application_type
  end

  def perform
    transform_attrs!
    PlanningApplication.create!(
      @attrs.merge(
        local_authority_id: @local_authority.id,
        application_type_id: @application_type.id,
        regulation_3: "pending",
        regulation_4: "pending",
        applicant_email: @attrs["applicant_email"].presence || "admin@example.com",
        ownership_certificate_checked: @attrs["ownership_certificate_checked"].presence || false
      )
    )
  end

  private

  def transform_attrs!
    @attrs["decision"] = case @attrs["decision"]&.strip&.upcase
    when "GRANT" then "granted"
    when "REFUSED" then "refused"
    when "NOT REQUIRED" then "not_required"
    else @attrs["decision"]
    end

    @attrs.delete("application_type") # still cleaning this as in original
  end
end
