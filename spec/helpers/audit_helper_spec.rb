# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditHelper do
  describe "#activity" do
    let(:assessor) { create(:user, name: "Polly") }
    let(:assigned_audit) { create(:audit, activity_type: "assigned", activity_information: "Maria") }
    let(:approved_audit) { create(:audit, activity_type: "assessed") }
    let(:challenged_audit) { create(:audit, activity_type: "challenged") }
    let(:created_audit) { create(:audit, activity_type: "created", activity_information: assessor.name) }
    let(:document_archived_audit) { create(:audit, activity_type: "archived") }

    it "returns the correct wording for an assessed audit" do
      expect(activity(approved_audit.activity_type)).to eq("Recommendation assessed")
    end

    it "returns the correct wording for an assigned audit" do
      expect(activity(assigned_audit.activity_type,
        assigned_audit.activity_information)).to eq("Application assigned to Maria")
    end

    it "returns the correct wording for an challenged audit" do
      expect(activity(challenged_audit.activity_type)).to eq("Recommendation challenged")
    end

    it "returns the correct wording for a created audit" do
      expect(activity(created_audit.activity_type,
        created_audit.activity_information)).to eq("Application created by Polly")
    end

    it "returns the correct wording for an archive audit" do
      expect(activity(document_archived_audit.activity_type)).to eq("Document archived")
    end

    context "when cancelled validation requests" do
      %w[
        additional_document_validation_request_cancelled
        description_change_validation_request_cancelled
        other_change_validation_request_cancelled
        red_line_boundary_change_validation_request_cancelled
        replacement_document_validation_request_cancelled
      ].each do |validation_request|
        let(validation_request) { create(:audit, activity_type: validation_request) }
      end

      it "returns the correct wording for additional_document_validation_request_cancelled audit" do
        expect(activity(additional_document_validation_request_cancelled.activity_type)).to eq(
          "Cancelled: validation request (new document#)"
        )
      end

      it "returns the correct wording for description_change_validation_request_cancelled audit" do
        expect(activity(description_change_validation_request_cancelled.activity_type)).to eq(
          "Cancelled: validation request (applicant approval for description change #)"
        )
      end

      it "returns the correct wording for other_change_validation_request_cancelled audit" do
        expect(activity(other_change_validation_request_cancelled.activity_type)).to eq(
          "Cancelled: validation request (other change from applicant#)"
        )
      end

      it "returns the correct wording for red_line_boundary_change_validation_request_cancelled audit" do
        expect(activity(red_line_boundary_change_validation_request_cancelled.activity_type)).to eq(
          "Cancelled: validation request (applicant approval for red line boundary change#)"
        )
      end

      it "returns the correct wording for replacement_document_validation_request_cancelled audit" do
        expect(activity(replacement_document_validation_request_cancelled.activity_type)).to eq(
          "Cancelled: validation request (replace document#)"
        )
      end
    end

    it "returns an Argument Error if audit activity does not exist" do
      expect { activity("does_not_exist") }.to raise_error(ArgumentError, "Activity type: does_not_exist is not valid")
    end
  end

  describe "#audit_entry_template" do
    let(:assessor) { create(:user, name: "Polly") }
    let(:validation_request_cancelled_audit) do
      create(:audit, activity_type: "additional_document_validation_request_cancelled")
    end
    let(:validation_request_audit) { create(:audit, activity_type: "other_change_validation_request_added") }
    let(:document_received_at_changed) { create(:audit, activity_type: "document_received_at_changed") }
    let(:submitted_audit) { create(:audit, activity_type: "submitted") }
    let(:random_audit) { create(:audit, activity_type: "created") }

    it "returns the correct audit activity type for a cancelled validation request" do
      expect(audit_entry_template(validation_request_cancelled_audit)).to eq("validation_request_cancelled")
    end

    it "returns the correct audit activity type for a validation request" do
      expect(audit_entry_template(validation_request_audit)).to eq("other_change_validation_request_added")
    end

    it "returns the correct audit activity type for document_received_at_changed" do
      expect(audit_entry_template(document_received_at_changed)).to eq("document_received_at_changed")
    end

    it "returns the correct audit activity type for submitting a planning application" do
      expect(audit_entry_template(submitted_audit)).to eq("submitted")
    end

    it "returns the generic template for an audit" do
      expect(audit_entry_template(random_audit)).to eq("generic_audit_entry")
    end
  end
end
