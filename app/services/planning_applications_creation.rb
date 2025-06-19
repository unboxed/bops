# frozen_string_literal: true

class PlanningApplicationsCreation
  ATTRIBUTES = %i[
    address_1
    agent_first_name
    agent_last_name
    agent_email
    applicant_first_name
    applicant_last_name
    applicant_email
    application_type_id
    assessment_in_progress_at
    awaiting_determination_at
    cil_liable
    decision
    description
    determination_date
    determined_at
    expiry_date
    invalidated_at
    valid_ownership_certificate
    parish_name
    payment_amount
    postcode
    previous_references
    reference
    received_at
    reporting_type_code
    returned_at
    target_date
    town
    uprn
    valid_description
    in_committee_at
    ownership_certificate_checked
    regulation_3
    regulation_4
    valid_fee
    valid_red_line_boundary
    validated_at
    ward
    withdrawn_at
    local_authority
  ].freeze

  def initialize(**params)
    ATTRIBUTES.each do |attribute|
      instance_variable_set(:"@#{attribute}", params[attribute])
    end
  end

  def perform
    importer
  end

  private

  attr_reader(*ATTRIBUTES)

  def importer
    pa = PlanningApplication.find_or_initialize_by(reference: reference)
    pa.update!(**planning_application_attributes)
    pa
  rescue => e
    Rails.logger.debug { "[IMPORT ERROR] #{e.class}: #{e.message}" }
    Rails.logger.debug pa.errors.full_messages.join(", ")
    raise
  end

  def planning_application_attributes
    {
      address_1:,
      agent_first_name:,
      agent_last_name:,
      agent_email:,
      applicant_first_name:,
      applicant_last_name:,
      applicant_email:,
      application_type_id:,
      assessment_in_progress_at:,
      awaiting_determination_at:,
      cil_liable:,
      decision:,
      description:,
      determination_date:,
      determined_at:,
      expiry_date:,
      invalidated_at:,
      valid_ownership_certificate:,
      parish_name:,
      payment_amount:,
      postcode:,
      previous_references:,
      reference:,
      received_at:,
      reporting_type_code:,
      returned_at:,
      target_date:,
      town:,
      uprn:,
      valid_description:,
      in_committee_at:,
      ownership_certificate_checked:,
      regulation_3:,
      regulation_4:,
      valid_fee:,
      valid_red_line_boundary:,
      validated_at:,
      ward:,
      withdrawn_at:,
      local_authority:
    }
  end
end
