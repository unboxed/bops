# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Layout/ArgumentAlignment, Layout/FirstArgumentIndentation, Layout/MultilineOperationIndentation
RSpec.describe PlanningApplicationsCreation do
  let(:local_authority) { create(:local_authority) }
  let(:application_type) { create(:application_type, local_authority: local_authority) }

  context "with an application that was determined in the past" do
    target_date = 2.weeks.ago.in_time_zone.to_date
    received_at_date = Time.zone.parse("2025-05-27 10:38:35.469341000 +0100")
    assessment_date = Time.zone.parse("2025-05-28 10:38:35.469341000 +0100")
    in_committee_at = Time.zone.parse("2025-05-29 10:38:35.469341000 +0100")
    determined_at = Time.zone.parse("2025-06-14 10:38:35.469341000 +0100")

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
        assessment_in_progress_at: assessment_date,
        awaiting_determination_at: nil,
        received_at: received_at_date,
        description: "Planning application for a shed with a purple roof",
        postcode: "AB1 2CD",
        town: "Big City",
        ward: "My Ward",
        uprn: "10000000001",
        parish_name: "My Parish",
        cil_liable: false,
        decision: "granted",
        invalidated_at: nil,
        valid_ownership_certificate: true,
        previous_references: ["HZY-43232"],
        payment_amount: 892,
        returned_at: nil,
        target_date: target_date,
        determined_at: determined_at,
        valid_description: true,
        in_committee_at: in_committee_at,
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
                      assessment_in_progress_at: assessment_date,
                      awaiting_determination_at: nil,
                      received_at: received_at_date,
                      description: "Planning application for a shed with a purple roof",
                      postcode: "AB1 2CD",
                      town: "Big City",
                      ward: "My Ward",
                      uprn: "10000000001",
                      parish_name: "My Parish",
                      cil_liable: false,
                      decision: "granted",
                      invalidated_at: nil,
                      valid_ownership_certificate: true,
                      previous_references: ["HZY-43232"],
                      returned_at: nil,
                      target_date: target_date,
                      determined_at: determined_at,
                      valid_description: true,
                      in_committee_at: in_committee_at,
                      ownership_certificate_checked: true,
                      regulation_3: false,
                      regulation_4: false,
                      valid_fee: true,
                      valid_red_line_boundary: true,
                      validated_at: nil,
                      withdrawn_at: nil,
                      local_authority: local_authority
                    )
      expect(pa.payment_amount).to be_within(0.001).of(892.0)
    end
  end

  context "with an application that is in the process of being determined" do
    received_at_date = Time.zone.parse("2025-05-27 10:38:35.469341000 +0100")

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
        assessment_in_progress_at: nil,
        awaiting_determination_at: nil,
        received_at: received_at_date,
        description: "Planning application for a shed with a purple roof",
        postcode: "AB1 2CD",
        town: "Big City",
        ward: "My Ward",
        uprn: "10000000001",
        parish_name: "My Parish",
        cil_liable: false,
        decision: "granted",
        invalidated_at: nil,
        determined_at: nil,
        valid_ownership_certificate: true,
        previous_references: ["HZY-43232"],
        payment_amount: 892,
        returned_at: nil,
        target_date: nil,
        valid_description: true,
        in_committee_at: nil,
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
                      assessment_in_progress_at: nil,
                      awaiting_determination_at: nil,
                      received_at: received_at_date,
                      description: "Planning application for a shed with a purple roof",
                      postcode: "AB1 2CD",
                      town: "Big City",
                      ward: "My Ward",
                      uprn: "10000000001",
                      parish_name: "My Parish",
                      cil_liable: false,
                      decision: "granted",
                      invalidated_at: nil,
                      valid_ownership_certificate: true,
                      previous_references: ["HZY-43232"],
                      payment_amount: 892,
                      returned_at: nil,
                      determined_at: nil,
                      target_date: 1.week.from_now.in_time_zone.to_date,
                      valid_description: true,
                      in_committee_at: nil,
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
end
# rubocop:enable Layout/ArgumentAlignment, Layout/FirstArgumentIndentation, Layout/MultilineOperationIndentation
