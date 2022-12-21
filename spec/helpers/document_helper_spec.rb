# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentHelper do
  describe "#titled_refrence_or_file_name" do
    it "returns the document reference if present" do
      document = create(:document, numbers: "REF123")

      expect(titled_reference_or_file_name(document)).to eq "Reference: REF123"
    end

    it "returns if reference missing the document name" do
      document = create(:document, numbers: "")

      # I can't control the name of the document name so always proposed-flooplan.png
      expect(titled_reference_or_file_name(document)).to eq "File name: proposed-floorplan.png"
    end
  end

  describe "#refrence_or_file_name" do
    it "returns the document reference if present" do
      document = create(:document, numbers: "REF123")

      expect(reference_or_file_name(document)).to eq "REF123"
    end

    it "returns if reference missing the document name" do
      document = create(:document, numbers: "")

      # I can't control the name of the document name so always proposed-flooplan.png
      expect(reference_or_file_name(document)).to eq "proposed-floorplan.png"
    end
  end
end
