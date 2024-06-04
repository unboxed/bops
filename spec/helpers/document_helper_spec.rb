# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentHelper do
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

  describe "#link_to_document" do
    include GovukVisuallyHiddenHelper
    include GovukLinkHelper

    let(:document) { create(:document) }

    it "adds view in new tab text" do
      link = link_to_document("hello world", document)
      expect(link).to match(/hello world \(opens in new tab\)/)
    end

    it "does not repeat view in new tab text" do
      link = link_to_document("View document in new window", document)
      expect(link).to match(/View document in new window/)
      expect(link).not_to match(/\(opens in new tab\)/)
    end
  end
end
