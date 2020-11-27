# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Drawing, type: :model do
  subject { FactoryBot.build :drawing }

  describe "scopes" do
    describe ".active" do
      let!(:active_drawing) { create :drawing }
      let!(:archived_drawing) { create :drawing, :archived }

      it "should return drawings that are not archived" do
        expect(Drawing.active).to match_array([active_drawing])
      end
    end

    describe ".has_proposed_tag" do
      let!(:untagged_drawing) { create :drawing }
      let!(:proposed_drawing) { create :drawing, :proposed_tags }
      let!(:existing_drawing) { create :drawing, :existing_tags }

      it "scopes drawings with proposed tags correctly" do
        expect(Drawing.has_proposed_tag).to match_array([proposed_drawing])
      end
    end

    describe ".has_empty_numbers" do
      let!(:numbered_drawing)        { create :drawing, numbers: "one, two" }
      let!(:drawing_without_numbers) { create :drawing }

      it "scopes drawings with proposed tags correctly" do
        expect(Drawing.has_empty_numbers).to match_array([drawing_without_numbers])
      end
    end
  end

  describe "validations" do
    before { subject.save }

    it "is valid for a png plan content type" do
      subject.plan.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/existing-roofplan.pdf")),
        filename: "existing-roofplan.png",
        content_type: "image/png"
      )

      expect(subject).to be_valid
    end

    it "is valid for a pdf plan content type" do
      subject.plan.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/existing-roofplan.pdf")),
        filename: "existing-roofplan.pdf",
        content_type: "application/pdf"
      )

      expect(subject).to be_valid
    end

    it "is invalid for an unpermitted plan content type" do
      subject.plan.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/bmp.bmp")),
        filename: "bmp.bmp",
        content_type: "image/bmp"
      )

      expect(subject).not_to be_valid
    end

    it "is invalid with any unpermitted tags" do
      subject.tags = [Drawing::TAGS.first, "not_a_tag"]

      expect(subject).not_to be_valid
      expect(subject.errors[:tags]).to eq ["Please choose valid tags"]
    end

    it "is valid with permitted tags" do
      subject.tags = [Drawing::TAGS.first, Drawing::TAGS.last]

      expect(subject).to be_valid
    end
  end

  describe "instance methods" do
    describe "#archive" do
      before { subject.archive ("scale") }

      it "archive reason should be correctly returned when assigned" do
        expect(subject.archive_reason).to eql("scale")
      end

      it "should be able to be archived with valid reason" do
        expect(subject.archived_at).not_to be(nil)
      end

      it "should return true when archived? method called" do
        expect(subject.archived?).to be true
      end
    end

    describe "#numbers=" do
      it "splits strings on commas, removing whitespace and superfluous commas" do
        subject.numbers = ""
        expect(subject[:numbers]).to eq([])

        subject.numbers = "just_the_one"
        expect(subject[:numbers]).to eq(["just_the_one"])

        subject.numbers = " one , two,,three     "
        expect(subject[:numbers]).to eq(["one", "two", "three"])
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
