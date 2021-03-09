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
  end

  describe "validations" do
    before { document.save }

    it "is valid for a png file content type" do
      document.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/existing-roofplan.pdf")),
        filename: "existing-roofplan.png",
        content_type: "image/png",
      )

      expect(document).to be_valid
    end

    it "is valid for a pdf file content type" do
      document.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/existing-roofplan.pdf")),
        filename: "existing-roofplan.pdf",
        content_type: "application/pdf",
      )

      expect(document).to be_valid
    end

    it "is invalid for an unpermitted file content type" do
      document.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/bmp.bmp")),
        filename: "bmp.bmp",
        content_type: "image/bmp",
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
  end
end
