# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Drawing, type: :model do
  subject { FactoryBot.build :drawing }

  describe "validations" do
    before { subject.save }

    it "is valid for a png plan content type" do
      subject.plan.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/existing-floorplan.png")),
        filename: "existing-floorplan.png",
        content_type: "image/png"
      )

      expect(subject).to be_valid
    end

    it "is valid for a pdf plan content type" do
      subject.plan.attach(
        io: File.open(Rails.root.join("spec/fixtures/images/existing-floorplan.pdf")),
        filename: "existing-floorplan.pdf",
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
  end

  describe "#archive" do
    before { subject.archive ("scale") }

    it "archive reason should be correcly returned when assigned" do
      expect(subject.archive_reason).to eql("scale")
    end

    it "should be able to be archived with valid reason" do
      expect(subject.archived_at).not_to be(nil)
    end

    it "should return true when archived? method called" do
      expect(subject.archived?).to be true
    end
  end
end
