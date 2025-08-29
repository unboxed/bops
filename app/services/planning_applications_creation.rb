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
    @warnings = []

    ATTRIBUTES.each do |attribute|
      value = params[attribute]
      value = false if %i[regulation_3 regulation_4].include?(attribute) && value.nil?
      instance_variable_set(:"@#{attribute}", value)
    end
  end

  def perform
    importer
  end

  attr_reader :warnings

  private

  attr_reader(*ATTRIBUTES)

  def importer
    case_record = CaseRecord.new(local_authority: planning_application_attributes[:local_authority])
    case_record.caseable = PlanningApplication.find_or_initialize_by(reference: reference)
    pa.update!(**planning_application_attributes)
  rescue => e
    Rails.logger.debug { "[IMPORT ERROR] #{e.class}: #{e.message}" }
    Rails.logger.debug pa.errors.full_messages.join(", ") if pa
    raise
  end

  def transform_decision
    case decision&.strip&.upcase
    when "GRANT"
      "granted"
    when "REFUSED"
      "refused"
    when "NOT REQUIRED"
      "not_required"
    end
  end

  def resolved_application_type_id
    raise "Missing application_type_id for reference #{reference}" if application_type_id.blank?

    type = ApplicationType.find_by(code: application_type_id)
    unless type
      @warnings << "Application type with code '#{application_type_id}' not found for planning application #{reference}; field omitted."
      raise "Application type with code '#{application_type_id}' not found"
    end

    type.id
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
      application_type_id: resolved_application_type_id,
      assessment_in_progress_at:,
      awaiting_determination_at:,
      cil_liable:,
      decision: transform_decision,
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
