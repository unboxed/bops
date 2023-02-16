# frozen_string_literal: true

require "rails_helper"

RSpec.describe Document do
  subject(:document) { build(:document) }

  it_behaves_like("Auditable") do
    subject { create(:document) }
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_document) { create(:document) }
      let!(:archived_document) { create(:document, :archived) }

      it "returns documents that are not archived" do
        expect(described_class.active).to match_array([active_document])
      end
    end

    describe ".by_created_at" do
      let!(:document1) { create(:document, created_at: 1.day.ago) }
      let!(:document2) { create(:document, created_at: Time.zone.now) }
      let!(:document3) { create(:document, created_at: 2.days.ago) }

      it "returns document sorted by created at" do
        expect(described_class.by_created_at).to eq([document3, document1, document2])
      end
    end
  end

  describe "validations" do
    before { document.save }

    it "has a valid factory" do
      expect(create(:document)).to be_valid
    end

    context "when a received date is set in the future" do
      it "is not valid" do
        document.received_at = 2.days.from_now

        expect(document).not_to be_valid
      end
    end

    context "when a received date is set to today" do
      it "is valid" do
        document.received_at = Time.zone.today

        expect(document).to be_valid
      end
    end

    context "when a received date is set in the past" do
      it "is valid" do
        document.received_at = 3.days.ago

        expect(document).to be_valid
      end
    end

    it "is valid for a png file content type" do
      document.file.attach(
        io: Rails.root.join("spec/fixtures/images/existing-roofplan.pdf").open,
        filename: "existing-roofplan.png",
        content_type: "image/png"
      )

      expect(document).to be_valid
    end

    it "is valid for a pdf file content type" do
      document.file.attach(
        io: Rails.root.join("spec/fixtures/images/existing-roofplan.pdf").open,
        filename: "existing-roofplan.pdf",
        content_type: "application/pdf"
      )

      expect(document).to be_valid
    end

    it "is invalid for an unpermitted file content type" do
      document.file.attach(
        io: Rails.root.join("spec/fixtures/images/image.gif").open,
        filename: "image.gif",
        content_type: "image/gif"
      )

      expect(document).not_to be_valid
    end

    it "is invalid with any unpermitted tags" do
      document.tags = [Document::TAGS.first, "not_a_tag"]

      expect(document).not_to be_valid
      expect(document.errors[:tags]).to eq ["Please choose valid tags"]
    end

    it "is valid with permitted tags" do
      document.tags = [Document::TAGS.first, Document::TAGS.last]

      expect(document).to be_valid
    end
  end

  describe "callbacks" do
    describe "::before_update #reset_replacement_document_validation_request_update_counter!" do
      let(:planning_application) { create(:planning_application, :invalidated) }
      let!(:document) { create(:document) }
      let(:replacement_document_validation_request1) do
        create(:replacement_document_validation_request, :open, planning_application: planning_application, new_document: document)
      end
      let(:replacement_document_validation_request2) do
        create(:replacement_document_validation_request, :open, planning_application: planning_application, old_document: document)
      end

      before { replacement_document_validation_request1.close! }

      context "when document is validated" do
        before { document.update(validated: true) }

        it "resets the update counter on the previous request where its new document is associated" do
          expect(replacement_document_validation_request1.validation_request.update_counter).to be(true)

          replacement_document_validation_request2

          expect(replacement_document_validation_request1.validation_request.reload.update_counter).to be(false)
        end
      end

      context "when document is archived" do
        before { document.update(archived_at: Time.current) }

        it "resets the update counter on the previous request where its new document is associated" do
          expect(replacement_document_validation_request1.validation_request.update_counter).to be(true)

          replacement_document_validation_request2

          expect(replacement_document_validation_request1.validation_request.reload.update_counter).to be(false)
        end
      end
    end
  end

  describe "instance methods" do
    describe "#archive" do
      context "when document can be archived" do
        before { document.archive("scale") }

        it "archive reason should be correctly returned when assigned" do
          expect(document.archive_reason).to eql("scale")
        end

        it "is able to be archived with valid reason" do
          expect(document.archived_at).not_to be_nil
        end

        it "returns true when archived? method called" do
          expect(document.archived?).to be true
        end
      end

      context "when document cannot be archived" do
        let!(:replacement_document_validation_request) do
          create(:replacement_document_validation_request, old_document: document)
        end

        before { document.replacement_document_validation_request = replacement_document_validation_request }

        it "raises an error if there is an associated replacement document validation request" do
          expect do
            document.archive("scale")
          end.to raise_error(
            Document::NotArchiveableError, "Cannot archive document with an open or pending validation request"
          )
        end
      end
    end

    describe "#invalidated_document_reason" do
      context "when there is an associated replacement_document_validation_request" do
        let!(:replacement_document_validation_request) do
          create(:replacement_document_validation_request, old_document: document, reason: "invalid!")
        end

        it "calls the super method" do
          expect(document.invalidated_document_reason).to eq("invalid!")
        end
      end

      context "when there is no associated replacement_document_validation_request" do
        before { document.update(invalidated_document_reason: "an invalid reason") }

        it "calls the replacement_document_validation_request reason" do
          expect(document.invalidated_document_reason).to eq("an invalid reason")
        end
      end
    end

    describe "#image_url" do
      let(:document) { create(:document) }

      context "when image is present" do
        let(:processed_active_storage_variant) do
          instance_double(
            ActiveStorage::VariantWithRecord,
            url: "http://www.example.com/test_image"
          )
        end

        before do
          allow_any_instance_of(ActiveStorage::VariantWithRecord)
            .to receive(:processed)
            .and_return(processed_active_storage_variant)
        end

        it "returns the file path to the image" do
          expect(
            document.image_url
          ).to eq(
            "http://www.example.com/test_image"
          )
        end
      end

      context "when image is missing" do
        before do
          allow_any_instance_of(ActiveStorage::VariantWithRecord)
            .to receive(:processed)
            .and_raise(ActiveStorage::PreviewError.new("Document stream is empty"))
        end

        it "returns nil" do
          expect(document.image_url).to be_nil
        end

        it "logs the error" do
          expect(Rails.logger)
            .to receive(:warn)
            .with("Image retrieval failed for document ##{document.id} with error 'Document stream is empty'")

          document.image_url
        end
      end
    end
  end

  describe ".referenced_in_decision_notice" do
    context "when referenced_in_decision_notice is true" do
      let(:document) do
        create(:document, referenced_in_decision_notice: true, numbers: "REF1")
      end

      it "includes document" do
        expect(
          described_class.referenced_in_decision_notice
        ).to include(
          document
        )
      end
    end

    context "when referenced_in_decision_notice is false" do
      let(:document) { create(:document, referenced_in_decision_notice: false) }

      it "includes document" do
        expect(
          described_class.referenced_in_decision_notice
        ).not_to include(
          document
        )
      end
    end
  end

  describe "#update_or_replace" do
    let(:planning_application) { create(:planning_application, :not_started) }

    let(:file_path1) do
      Rails.root.join("spec/fixtures/images/proposed-floorplan.png")
    end

    let(:file_path2) do
      Rails.root.join("spec/fixtures/images/proposed-roofplan.png")
    end

    let(:file1) { Rack::Test::UploadedFile.new(file_path1, "image/png") }
    let(:file2) { Rack::Test::UploadedFile.new(file_path2, "image/png") }

    let(:document) do
      create(
        :document,
        file: file1,
        planning_application: planning_application,
        numbers: "DOC123"
      )
    end

    context "when there is no 'file' attribute" do
      let(:attributes) do
        { numbers: "DOC345" }
      end

      it "updates existing document" do
        document.update_or_replace(attributes)

        expect(document.reload.numbers).to eq("DOC345")
      end

      context "when the attributes are invalid" do
        let(:attributes) do
          { referenced_in_decision_notice: true, numbers: "" }
        end

        it "returns false" do
          expect(document.update_or_replace(attributes)).to be(false)
        end

        it "sets error" do
          document.update_or_replace(attributes)

          expect(document.errors.messages[:numbers]).to contain_exactly(
            "All documents listed on the decision notice must have a document number"
          )
        end
      end
    end

    context "when there is a 'file' attribute" do
      let(:attributes) do
        { file: file2 }
      end

      it "archives existing document" do
        travel_to(Time.zone.local(2022, 12, 23)) do
          document.update_or_replace(attributes)
        end

        expect(document).to have_attributes(
          archive_reason: "Replacement document uploaded",
          archived_at: Time.zone.local(2022, 12, 23).to_datetime
        )
      end

      it "does not update existing document" do
        document.update_or_replace(attributes)

        expect(
          document.reload.file.blob.filename
        ).to eq(
          "proposed-floorplan.png"
        )
      end

      it "creates new document with attributes" do
        document.update_or_replace(attributes)

        new_document = planning_application.reload.documents.last

        expect(
          new_document.file.blob.filename
        ).to eq(
          "proposed-roofplan.png"
        )
      end

      context "when there is an open replacement request" do
        before do
          create(
            :replacement_document_validation_request,
            old_document: document,
            planning_application: planning_application
          )
        end

        it "returns false" do
          expect(document.update_or_replace(attributes)).to be(false)
        end

        it "sets error" do
          document.update_or_replace(attributes)

          expect(document.errors.messages[:file]).to contain_exactly(
            "You cannot replace the file when there is an open document replacement request"
          )
        end
      end
    end
  end
end
