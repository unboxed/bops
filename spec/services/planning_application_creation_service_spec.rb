# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationCreationService, type: :service do
  let(:local_authority) { create(:local_authority) }
  let(:application_type) { create(:application_type, local_authority:) }

  let(:attributes) do
    {
      "reference" => "PA-001",
      "description" => "Test planning app",
      "received_at" => Time.zone.today.to_s,
      "decision" => "GRANT",
      "determined_at" => Time.zone.today.to_s,
      "address_1" => "123 Test St",
      "agent_first_name" => "John",
      "agent_last_name" => "Doe",
      "applicant_first_name" => "Jane",
      "applicant_last_name" => "Smith",
      "assessment_in_progress_at" => Time.zone.today.to_s,
      "awaiting_determination_at" => Time.zone.today.to_s,
      "cil_liable" => true,
      "determination_date" => Time.zone.today.to_s,
      "expiry_date" => Time.zone.today.to_s,
      "invalidated_at" => Time.zone.today.to_s,
      "valid_ownership_certificate" => "",
      "parish_name" => "Test Parish",
      "payment_amount" => "123.45",
      "postcode" => "SE1 1AA",
      "previous_references" => "PP-HH-123",
      "reporting_type_code" => "",
      "returned_at" => Time.zone.today.to_s,
      "target_date" => Time.zone.today.to_s,
      "town" => "Test Town",
      "uprn" => "1234567890",
      "valid_description" => "Yes",
      "in_committee_at" => Time.zone.today.to_s,
      "ownership_certificate_checked" => true,
      "regulation_3" => true,
      "regulation_4" => false,
      "valid_fee" => "",
      "valid_red_line_boundary" => "",
      "validated_at" => Time.zone.today.to_s,
      "ward" => "",
      "withdrawn_at" => Time.zone.today.to_s
    }
  end

  it "creates a PlanningApplication with a transformed decision" do
    service = described_class.new(attributes, local_authority:, application_type:)
    app = service.perform

    expect(app).to be_persisted
    expect(app.decision).to eq("granted")
    expect(app.local_authority_id).to eq(local_authority.id)
    expect(app.application_type_id).to eq(application_type.id)
  end
end
