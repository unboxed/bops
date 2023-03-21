# frozen_string_literal: true

require "rails_helper"

RSpec.describe UploadDocumentsService, type: :service do
  describe "#call" do
    let(:planning_application) { create(:planning_application) }

    let(:files) do
      [
        {
          filename: "https://example.com/proposed-floorplan.png",
          applicant_description: "first floor plan",
          tags: ["Floor"]
        }
      ]
    end

    let(:service) do
      described_class.new(
        files:,
        planning_application:
      )
    end

    let(:file_path) do
      Rails.root.join("spec/fixtures/images/proposed-floorplan.png")
    end

    let(:response) do
      {
        status: 200,
        body: File.open(file_path),
        headers: { "Content-Type": "image/png" }
      }
    end

    before do
      stub_request(:get, "https://example.com/proposed-floorplan.png")
        .to_return(response)
    end

    it "creates a new document" do
      expect { service.call }
        .to change { planning_application.documents.count }
        .by(1)

      expect(planning_application.documents.last).to have_attributes(
        tags: ["Floor"],
        applicant_description: "first floor plan"
      )
    end
  end
end
