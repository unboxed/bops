# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditHelper, type: :helper do
  describe "#activity" do
    let(:assessor) { create :user, name: "Polly" }
    let(:assigned_audit) { create :audit, activity_type: "assigned", activity_information: "Maria" }
    let(:approved_audit) { create :audit, activity_type: "assessed" }
    let(:challenged_audit) { create :audit, activity_type: "challenged" }
    let(:created_audit) { create :audit, activity_type: "created", activity_information: assessor.name }
    let(:document_archived_audit) { create :audit, activity_type: "archived" }

    it "returns the correct wording for an assessed audit" do
      expect(activity(approved_audit.activity_type)).to eq("Recommendation submitted")
    end

    it "returns the correct wording for an assigned audit" do
      expect(activity(assigned_audit.activity_type, assigned_audit.activity_information)).to eq("Application assigned to Maria")
    end

    it "returns the correct wording for an challenged audit" do
      expect(activity(challenged_audit.activity_type)).to eq("Recommendation challenged")
    end

    it "returns the correct wording for a created audit" do
      expect(activity(created_audit.activity_type, created_audit.activity_information)).to eq("Application created by Polly")
    end

    it "returns the correct wording for an archive audit" do
      expect(activity(document_archived_audit.activity_type)).to eq("Document archived")
    end
  end
end
