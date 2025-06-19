require "rails_helper"

RSpec.describe PlanningApplicationsCreation do
  let(:local_authority) { create(:local_authority) }
  let(:application_type) { create(:application_type, local_authority: local_authority) }

  let(:params) do
    {
      address_1: "1 High Street",
      agent_first_name: "Alice",
      agent_last_name: "Agent",
      agent_email: "agent@example.com",
      applicant_first_name: "Bob",
      applicant_last_name: "Builder",
      applicant_email: "bob@example.com",
      application_type_id: application_type.id,
      assessment_in_progress_at: Time.zone.now,
      received_at: Time.zone.today,
      description: "Planning application for a shed with a purple roof",
      postcode: "AB1 2CD",
      town: "Big City",
      uprn: "10000000001",
      cil_liable: false,
      decision: "granted",
      invalidated_at: nil,
      valid_ownership_certificate: true,
      payment_amount: 892,
      returned_at: nil,
      valid_description: true,
      in_committee_at: Time.zone.now,
      ownership_certificate_checked: true,
      regulation_3: false,
      regulation_4: false,
      valid_fee: true,
      valid_red_line_boundary: true,
      validated_at: nil,
      withdrawn_at: nil,
      local_authority: local_authority
    }
  end

  it "creates a new PlanningApplication with the correct attributes" do
    expect {
      described_class.new(**params).perform
    }.to change(PlanningApplication, :count).by(1)

    pa = PlanningApplication.find_by(uprn: "10000000001")
    expect(pa).to have_attributes(
                    address_1: "1 High Street",
                    agent_first_name: "Alice",
                    agent_last_name: "Agent",
                    agent_email: "agent@example.com",
                    applicant_first_name: "Bob",
                    applicant_last_name: "Builder",
                    applicant_email: "bob@example.com",
                    application_type_id: application_type.id,
                    description: "Planning application for a shed with a purple roof",
                    postcode: "AB1 2CD",
                    town: "Big City",
                    uprn: "10000000001",
                    cil_liable: false,
                    decision: "granted",
                    determined_at: nil,
                    invalidated_at: nil,
                    valid_ownership_certificate: true,
                    returned_at: nil,
                    valid_description: true,
                    ownership_certificate_checked: true,
                    regulation_3: false,
                    regulation_4: false,
                    valid_fee: true,
                    valid_red_line_boundary: true,
                    validated_at: nil,
                    withdrawn_at: nil,
                    local_authority: local_authority
                  )
  end
end
