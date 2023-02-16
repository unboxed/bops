# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReplacementDocumentValidationRequest do
  it_behaves_like "ValidationRequest", described_class, "replacement_document_validation_request"

  it_behaves_like("Auditable") do
    subject { create(:replacement_document_validation_request) }
  end

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

      it "returns replacement_document_validation_requests that are open or pending" do
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

      it "returns replacement_document_validation_requests where there is an associated active document" do
        expect(described_class.with_active_document).to match_array(
          [replacement_document_validation_request2, replacement_document_validation_request3]
        )
      end
    end
  end

  describe "callbacks" do
    describe "::before_destroy #reset_document_invalidation" do
      let!(:document) do
        create(:document, validated: false, invalidated_document_reason: "Invalid")
      end
      let!(:replacement_document_validation_request) do
        create(:replacement_document_validation_request, :pending, old_document: document)
      end

      before { replacement_document_validation_request.destroy! }

      it "updates and resets the validation fields on the associated document" do
        expect(document.reload.invalidated_document_reason).to be_nil
        expect(document.validated).to be_nil
      end
    end

    describe "::before_create #ensure_planning_application_not_validated!" do
      context "when a planning application has been validated" do
        let(:planning_application) { create(:planning_application, :in_assessment) }
        let(:replacement_document_validation_request) do
          create(:replacement_document_validation_request, planning_application:)
        end

        it "allows a replacement_document_validation_request to be created" do
          expect do
            replacement_document_validation_request
          end.not_to raise_error(ValidationRequestable::ValidationRequestNotCreatableError,
                                 "Cannot create Replacement Document Validation Request when planning application has been validated")
        end
      end
    end

    describe "::before_create #reset_replacement_document_validation_request_update_counter!" do
      let(:planning_application) { create(:planning_application, :invalidated) }
      let!(:document) { create(:document) }
      let(:replacement_document_validation_request1) do
        create(:replacement_document_validation_request, :open, planning_application:, new_document: document)
      end
      let(:replacement_document_validation_request2) do
        create(:replacement_document_validation_request, :open, planning_application:, old_document: document)
      end

      before { replacement_document_validation_request1.close! }

      it "resets the update counter on the previous request where its new document is associated" do
        expect(replacement_document_validation_request1.validation_request.update_counter).to be(true)

        replacement_document_validation_request2

        expect(replacement_document_validation_request1.validation_request.reload.update_counter).to be(false)
      end
    end
  end

  describe "events" do
    let!(:replacement_document_validation_request) { create(:replacement_document_validation_request, :open) }

    describe "#close" do
      it "sets updated_counter to true on the associated validation request" do
        replacement_document_validation_request.close!

        expect(replacement_document_validation_request.update_counter?).to be(true)
      end
    end
  end

  describe "#replace_document!" do
    let(:planning_application) { create(:planning_application, :not_started) }

    let(:file_path1) do
      Rails.root.join("spec/fixtures/images/proposed-floorplan.png")
    end

    let(:file_path2) do
      Rails.root.join("spec/fixtures/images/proposed-roofplan.png")
    end

    let(:file1) { Rack::Test::UploadedFile.new(file_path1, "image/png") }
    let(:file2) { Rack::Test::UploadedFile.new(file_path2, "image/png") }

    let(:old_document) do
      create(
        :document,
        file: file1,
        planning_application:,
        numbers: "DOC123",
        tags: ["Front"]
      )
    end

    let(:replacement_document_validation_request) do
      create(
        :replacement_document_validation_request,
        old_document:,
        new_document: nil,
        state: :open,
        planning_application:
      )
    end

    it "archives old document" do
      travel_to(Time.zone.local(2022, 12, 23)) do
        replacement_document_validation_request.replace_document!(
          file: file2,
          reason: "reason"
        )
      end

      expect(old_document).to have_attributes(
        archive_reason: "reason",
        archived_at: Time.zone.local(2022, 12, 23).to_datetime
      )
    end

    it "saves file to new document" do
      replacement_document_validation_request.replace_document!(
        file: file2,
        reason: "reason"
      )

      new_document = replacement_document_validation_request.reload.new_document

      expect(
        new_document.file.blob.filename
      ).to eq(
        "proposed-roofplan.png"
      )
    end

    it "copies reference number and tags to new document" do
      replacement_document_validation_request.replace_document!(
        file: file2,
        reason: "reason"
      )

      expect(
        replacement_document_validation_request.reload.new_document
      ).to have_attributes(
        numbers: "DOC123",
        tags: ["Front"]
      )
    end

    it "closes request" do
      replacement_document_validation_request.replace_document!(
        file: file2,
        reason: "reason"
      )

      expect(replacement_document_validation_request.state).to eq("closed")
    end
  end
end
