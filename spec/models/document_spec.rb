# frozen_string_literal: true

require "rails_helper"

RSpec.describe Document, type: :model do
  subject(:document) { FactoryBot.build :document }

  describe "scopes" do
    describe ".active" do
      let!(:active_document) { create :document }
      let!(:archived_document) { create :document, :archived }

      it "returns documents that are not archived" do
        expect(described_class.active).to match_array([active_document])
      end
    end

    describe ".by_created_at" do
      let!(:document1) { create(:document, created_at: Time.zone.now - 1.day) }
      let!(:document2) { create(:document, created_at: Time.zone.now) }
      let!(:document3) { create(:document, created_at: Time.zone.now - 2.days) }

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
        io: File.open(Rails.root.join("spec/fixtures/images/existing-roofplan.pdf")),
        filename: "existing-roofplan.png",
        content_type: "image/png"
      )

      expect(document).to be_valid
    end

    it "is valid for a pdf file content type" do
      document.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/existing-roofplan.pdf")),
        filename: "existing-roofplan.pdf",
        content_type: "application/pdf"
      )

      expect(document).to be_valid
    end

    it "is invalid for an unpermitted file content type" do
      document.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/bmp.bmp")),
        filename: "bmp.bmp",
        content_type: "image/bmp"
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

  describe "instance methods" do
    describe "#archive" do
      before { document.archive("scale") }

      it "archive reason should be correctly returned when assigned" do
        expect(document.archive_reason).to eql("scale")
      end

      it "is able to be archived with valid reason" do
        expect(document.archived_at).not_to be(nil)
      end

      it "returns true when archived? method called" do
        expect(document.archived?).to be true
      end
    end

    describe "#invalidated_document_reason" do
      context "when there is an associated replacement_document_validation_request" do
        let!(:replacement_document_validation_request) do
          create :replacement_document_validation_request, old_document: document, reason: "invalid!"
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
  end
end
