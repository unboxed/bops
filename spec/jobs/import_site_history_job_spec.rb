# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImportSiteHistoryJob do
  let(:local_authority) { create(:local_authority) }
  let(:application_type) { create(:application_type, id: 1, local_authority: local_authority) }
  let(:csv_path) { Rails.root.join("tmp/SiteHistoryBuckinghamshire.csv") }

  before do
    File.write(csv_path, <<~CSV)
      reference,address_1,agent_first_name,agent_last_name,agent_email,applicant_first_name,applicant_last_name,applicant_email,application_type_id,assessment_in_progress_at,awaiting_determination_at,received_at,description,postcode,town,ward,uprn,parish_name,cil_liable,decision,invalidated_at,valid_ownership_certificate,previous_references,payment_amount,returned_at,target_date,valid_description,in_committee_at,ownership_certificate_checked,regulation_3,regulation_4,valid_fee,valid_red_line_boundary,validated_at
      ABC123,1 High Street,Alice,Agent,agent@example.com,Bob,Builder,bob@example.com,#{application_type.id},2025-06-01T10:00:00,,2025-05-27T10:38:35,Planning application for a shed with a purple roof,AB1 2CD,Big City,My Ward,10000000001,My Parish,false,GRANT,,true,HZY-43232,892,,2025-06-19,true,2025-06-05T14:00:00,true,false,false,true,true,
    CSV

    Rails.configuration.import_config = {
      local_import_file_enabled: true,
      import_bucket: "bops-test-import"
    }

    allow(PlanningApplicationsCreation).to receive(:new).and_call_original
  end

  after do
    File.delete(csv_path) if File.exist?(csv_path)
  end

  it "imports planning applications from local CSV" do
    expect {
      described_class.new.perform(local_authority_name: "Buckinghamshire", create_class_name: "PlanningApplicationsCreation")
    }.to change(PlanningApplication, :count).by(1)

    expect(PlanningApplicationsCreation).to have_received(:new).with(
      hash_including(
        reference: "ABC123",
        address_1: "1 High Street",
        agent_email: "agent@example.com",
        agent_first_name: "Alice",
        agent_last_name: "Agent",
        applicant_email: "bob@example.com",
        applicant_first_name: "Bob",
        applicant_last_name: "Builder",
        application_type_id: "1",
        assessment_in_progress_at: "2025-06-01T10:00:00",
        awaiting_determination_at: nil,
        cil_liable: "false",
        decision: "GRANT",
        description: "Planning application for a shed with a purple roof",
        in_committee_at: "2025-06-05T14:00:00",
        invalidated_at: nil,
        local_authority: local_authority,
        ownership_certificate_checked: "true",
        parish_name: "My Parish",
        payment_amount: "892",
        postcode: "AB1 2CD",
        previous_references: ["HZY-43232"],
        received_at: "2025-05-27T10:38:35",
        regulation_3: "false",
        regulation_4: "false",
        returned_at: nil,
        target_date: "2025-06-19",
        town: "Big City",
        uprn: "10000000001",
        valid_description: "true",
        valid_fee: "true",
        valid_ownership_certificate: "true",
        valid_red_line_boundary: "true",
        validated_at: nil,
        ward: "My Ward"
      )
    )
  end
end
