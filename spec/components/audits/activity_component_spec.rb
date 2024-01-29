# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audits::ActivityComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:audit_template) do
    described_class.new(audit:).audit_template
  end

  context "when there is an activity type for a cancelled validation request" do
    let(:audit) do
      create(:audit, activity_type: "additional_document_validation_request_cancelled", planning_application:)
    end

    it "returns the correct template for a cancelled validation request" do
      expect(audit_template).to eq("validation_request_cancelled")
    end
  end

  context "when there is an activity type for an auto closed request" do
    let(:audit) { create(:audit, activity_type: "red_line_boundary_change_validation_request_auto_closed") }

    it "returns the correct other_change_validation_request_added template" do
      expect(audit_template).to eq("red_line_boundary_change_validation_request_auto_closed")
    end
  end

  context "all others return a generic audit entry" do
    let(:audit) { create(:audit, activity_type: "submitted") }

    it "returns the submitted template" do
      expect(audit_template).to eq("generic_audit_entry")
    end

    let(:audit) { create(:audit, activity_type: "created") }

    it "returns the generic template" do
      expect(audit_template).to eq("generic_audit_entry")
    end
  end
end
