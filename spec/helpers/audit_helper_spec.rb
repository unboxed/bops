# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditHelper, type: :helper do
  describe "#activity" do
    let(:assessor) { create :user }
    let(:approved_audit) { create :audit, activity_type: "assessed" }
    let(:created_audit) { create :audit, activity_type: "created" }

    it "returns the correct activity audit" do
      expect(activity(approved_audit.activity_type)).to eq("Application approved")
      expect(activity(created_audit.activity_type)).to eq("Application created")
    end
  end
end
