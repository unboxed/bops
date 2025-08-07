# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImportSiteHistoryJob do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:case_record) { build(:case_record, local_authority:) }
  let!(:application_type) { create(:application_type, :planning_permission) }
  let!(:planning_application) { create(:planning_application, local_authority: local_authority, case_record: case_record, application_type: application_type, previous_references: ["APP/2025/1234", "OLD/0001"]) }
  let!(:csv_path) { Rails.root.join("tmp/SiteNoticesBuckinghamshire.csv") }

  before do
    File.write(csv_path, <<~CSV)
      reference,displayed_at,expiry_date
      APP/2025/1234,25/01/2019 00:00,2025-06-01T10:00:00
    CSV

    Rails.configuration.import_config = {
      import_bucket: "bops-test-import"
    }

    allow(Rails.env).to receive(:local?).and_return(true)

    allow(SiteNoticesCreation).to receive(:new).and_call_original
  end

  after do
    File.delete(csv_path) if File.exist?(csv_path)
  end

  it "imports site notices from local CSV" do
    expect {
      described_class.new.perform(local_authority_name: "Buckinghamshire", create_class_name: "SiteNoticesCreation")
    }.to change(SiteNotice, :count).by(1)

    expect(SiteNoticesCreation).to have_received(:new).with(
      hash_including
    )
  end
end
