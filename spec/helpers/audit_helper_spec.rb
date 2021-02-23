# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditHelper, type: :helper do
  describe "#activity" do
    let(:assessor) { create :user }
    let(:approved_audit) { create :audit, activity_type: "assessed", activity_information: {comment: "This looks good"}.to_json }
    let(:challenged_audit) { create :audit, activity_type: "challenged", activity_information: {comment: "This does not look good"}.to_json }
    let(:created_audit) { create :audit, activity_type: "created" }
    let(:document_archived_audit) { create :audit, activity_type: "archived", activity_information: {filename: "proposed-floorplan/png"}.to_json }

    it "returns the correct wording for an assessment audit" do
      expect(activity(approved_audit.activity_type, approved_audit.activity_information))
          .to eq(["Application approved", "This looks good"])
    end

    it "returns the correct wording for an challenge audit" do
      expect(activity(challenged_audit.activity_type, challenged_audit.activity_information))
          .to eq(["Application challenged", "This does not look good"])
    end

    it "returns the correct wording for an assessment audit" do
      expect(activity(created_audit.activity_type)).to eq("Application created")
    end

    it "returns the correct wording for an archive audit" do
      expect(activity(document_archived_audit.activity_type, document_archived_audit.activity_information))
          .to eq(["Document archived", "proposed-floorplan/png"])
    end
  end
end
