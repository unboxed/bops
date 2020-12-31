# frozen_string_literal: true

require "rails_helper"

RSpec.describe Document, type: :model do
  subject { FactoryBot.build :document }

  describe "scopes" do
    describe ".active" do
      let!(:active_document) { create :document }
      let!(:archived_document) { create :document, :archived }

      it "returns documents that are not archived" do
        expect(described_class.active).to match_array([active_document])
      end
    end

    describe ".has_proposed_tag" do
      let!(:untagged_document) { create :document }
      let!(:proposed_document) { create :document, :proposed_tags }
      let!(:existing_document) { create :document, :existing_tags }

      it "scopes documents with proposed tags correctly" do
        expect(described_class.has_proposed_tag).to match_array([proposed_document])
      end
    end

    describe ".has_empty_numbers" do
      let!(:numbered_document)        { create :document, numbers: "one, two" }
      let!(:document_without_numbers) { create :document }

      it "scopes documents with proposed tags correctly" do
        expect(described_class.has_empty_numbers).to match_array([document_without_numbers])
      end
    end
  end

  describe "validations" do
    before { subject.save }

    it "is valid for a png file content type" do
      subject.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/existing-roofplan.pdf")),
        filename: "existing-roofplan.png",
        content_type: "image/png",
      )

      expect(subject).to be_valid
    end

    it "is valid for a pdf file content type" do
      subject.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/existing-roofplan.pdf")),
        filename: "existing-roofplan.pdf",
        content_type: "application/pdf",
      )

      expect(subject).to be_valid
    end

    it "is invalid for an unpermitted file content type" do
      subject.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/bmp.bmp")),
        filename: "bmp.bmp",
        content_type: "image/bmp",
      )

      expect(subject).not_to be_valid
    end

    it "is invalid with any unpermitted tags" do
      subject.tags = [Document::TAGS.first, "not_a_tag"]

      expect(subject).not_to be_valid
      expect(subject.errors[:tags]).to eq ["Please choose valid tags"]
    end

    it "is valid with permitted tags" do
      subject.tags = [Document::TAGS.first, Document::TAGS.last]

      expect(subject).to be_valid
    end
  end

  describe "instance methods" do
    describe "#archive" do
      before { subject.archive("scale") }

      it "archive reason should be correctly returned when assigned" do
        expect(subject.archive_reason).to eql("scale")
      end

      it "is able to be archived with valid reason" do
        expect(subject.archived_at).not_to be(nil)
      end

      it "returns true when archived? method called" do
        expect(subject.archived?).to be true
      end
    end

    describe "#numbers=" do
      it "splits strings on commas, removing whitespace and superfluous commas" do
        subject.numbers = ""
        expect(subject[:numbers]).to eq([])

        subject.numbers = "just_the_one"
        expect(subject[:numbers]).to eq(%w[just_the_one])

        subject.numbers = " one , two,,three     "
        expect(subject[:numbers]).to eq(%w[one two three])
      end
    end

    describe "#numbers" do
      it "returns underlying array as a single comma separated string" do
        subject[:numbers] = ["one with space", "two"]

        expect(subject.numbers).to eq "one with space, two"
      end
    end
  end
end
