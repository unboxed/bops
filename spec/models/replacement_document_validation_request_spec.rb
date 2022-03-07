# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReplacementDocumentValidationRequest, type: :model do
  it_behaves_like "ValidationRequest", described_class, "replacement_document_validation_request"

  describe "validations" do
    subject(:replacement_document_validation_request) { described_class.new }

    describe "#reason" do
      it "validates presence" do
        expect do
          replacement_document_validation_request.valid?
        end.to change {
          replacement_document_validation_request.errors[:reason]
        }.to ["can't be blank"]
      end
    end

    describe "#user" do
      it "validates presence" do
        expect do
          replacement_document_validation_request.valid?
        end.to change {
          replacement_document_validation_request.errors[:user]
        }.to ["must exist"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect do
          replacement_document_validation_request.valid?
        end.to change {
          replacement_document_validation_request.errors[:planning_application]
        }.to ["must exist"]
      end
    end

    describe "#old_document" do
      it "validates presence" do
        expect do
          replacement_document_validation_request.valid?
        end.to change {
          replacement_document_validation_request.errors[:old_document]
        }.to ["must exist"]
      end
    end
  end

  describe "scopes" do
    describe ".open_or_pending" do
      before do
        create(:replacement_document_validation_request, :closed)
        create(:replacement_document_validation_request, :cancelled)
      end

      let!(:replacement_document_validation_request1) do
        create(:replacement_document_validation_request, :open)
      end
      let!(:replacement_document_validation_request3) do
        create(:replacement_document_validation_request, :pending)
      end

      it "returns replacement_document_validation_request sorted by created at desc (i.e. most recent first)" do
        expect(described_class.open_or_pending).to match_array(
          [replacement_document_validation_request1, replacement_document_validation_request3]
        )
      end
    end

    describe ".with_active_document" do
      let(:document1) { create(:document, :archived) }
      let!(:replacement_document_validation_request2) do
        create(:replacement_document_validation_request, old_document: document2)
      end
      let!(:replacement_document_validation_request3) do
        create(:replacement_document_validation_request, old_document: document3)
      end
      let(:document2) { create(:document) }
      let(:document3) { create(:document) }

      before do
        create(:replacement_document_validation_request, old_document: document1)
      end

      it "returns replacement_document_validation_request sorted by created at desc (i.e. most recent first)" do
        expect(described_class.with_active_document).to match_array(
          [replacement_document_validation_request2, replacement_document_validation_request3]
        )
      end
    end
  end

  describe "callbacks" do
    describe "::before_destroy" do
      let!(:document) do
        create :document, validated: false, invalidated_document_reason: "Invalid"
      end
      let!(:replacement_document_validation_request) do
        create :replacement_document_validation_request, :pending, old_document: document
      end

      before { replacement_document_validation_request.destroy! }

      it "updates and resets the validation fields on the associated document" do
        expect(document.reload.invalidated_document_reason).to eq(nil)
        expect(document.validated).to eq(nil)
      end
    end
  end
end
