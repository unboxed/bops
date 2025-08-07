# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteNoticesCreation do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:case_record) { build(:case_record, local_authority:) }
  let(:application_type) { create(:application_type, :planning_permission) }

  context "when a matching planning application exists" do
    let(:reference) { "APP/2025/1234" }
    let(:planning_application) do
      create(:planning_application, local_authority: local_authority, case_record: case_record, application_type: application_type, previous_references: ["APP/2025/1234", "OLD/0001"])
    end

    let(:params) do
      {
        reference: reference,
        displayed_at: Date.new(2025, 8, 1),
        expiry_date: Date.new(2025, 8, 15)
      }
    end

    before { planning_application }

    it "creates a SiteNotice linked to the correct planning application" do
      expect {
        described_class.new(**params).perform
      }.to change(SiteNotice, :count).by(1)

      site_notice = SiteNotice.last
      expect(site_notice.displayed_at.to_date).to eq(Date.new(2025, 8, 1))
      expect(site_notice.expiry_date.to_date).to eq(Date.new(2025, 8, 15))
      expect(site_notice.planning_application_id).to eq(planning_application.id)
    end
  end

  context "when no matching planning application exists" do
    let(:params) do
      {
        reference: "APP/9999/0000",
        displayed_at: Date.new(2025, 8, 1),
        expiry_date: Date.new(2025, 8, 15)
      }
    end

    it "does not create a SiteNotice" do
      expect {
        described_class.new(**params).perform
      }.not_to change(SiteNotice, :count)
    end
  end
end
