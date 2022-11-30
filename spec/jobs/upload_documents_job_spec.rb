# frozen_string_literal: true

require "rails_helper"

RSpec.describe UploadDocumentsJob, type: :job do
  describe "#perform" do
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

    def perform_job
      perform_enqueued_jobs do
        described_class.perform_later(
          files: files,
          planning_application: planning_application
        )
      end
    end

    it "creates a new document" do
      expect { perform_job }
        .to change { planning_application.documents.count }
        .by(1)
    end

    it "saves document attributes correctly" do
      perform_job

      expect(planning_application.documents.last).to have_attributes(
        tags: ["Floor"],
        applicant_description: "first floor plan"
      )
    end

    it "saves filename correctly" do
      perform_job

      expect(
        planning_application.documents.last.file.blob.filename
      ).to eq(
        "proposed-floorplan.png"
      )
    end

    context "when the file type is not allowed" do
      let(:response) do
        {
          status: 200,
          body: File.open(file_path),
          headers: { "Content-Type": "text/plain" }
        }
      end

      it "raises an error" do
        # rubocop:disable RSpec/UnspecifiedException
        expect { perform_job }.to raise_error
        # rubocop:enable RSpec/UnspecifiedException
      end
    end

    context "when the request to retrieve the file fails" do
      before do
        allow(URI).to receive(:parse).and_raise(OpenURI::HTTPError)
      end

      it "raises an error" do
        # rubocop:disable RSpec/UnspecifiedException
        expect { perform_job }.to raise_error
        # rubocop:enable RSpec/UnspecifiedException
      end
    end
  end
end
