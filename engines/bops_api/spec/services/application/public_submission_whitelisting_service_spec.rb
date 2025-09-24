# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::PublicSubmissionWhitelistingService, type: :service do
  describe "#call" do
    let!(:local_authority) { create(:local_authority) }

    let(:submission) { json_fixture_api("examples/odp/v0.6.0/validPlanningPermission.json") }
    let(:planx_planning_data) { create(:planx_planning_data, params_v2: submission) }

    let(:published_document) { create(:document, :with_file, :with_tags, publishable: true) }
    let(:unpublished_document) { create(:document, :with_other_file, :floorplan_tags, publishable: false) }

    let(:planning_application) do
      create(
        :planning_application,
        :determined,
        documents: [published_document, unpublished_document],
        local_authority:,
        planx_planning_data:
      )
    end

    subject(:whitelisted_submission) do
      described_class.new(planning_application:).call
    end

    it "only shows the whitelisted fields in the submission" do
      expect(whitelisted_submission.dig(:data, :application, :type)).to be_present
      expect(whitelisted_submission.dig(:data, :applicant, :email)).not_to be_present
      expect(whitelisted_submission.dig(:metadata)).not_to be_present
    end

    it "does not expose the fee information in the submission responses" do
      expect(whitelisted_submission.dig(:data, :application)).not_to have_key(:fee)
    end

    context "with publishable and unpublishable documents" do
      let(:filename) do
        URI.decode_uri_component(File.basename(URI.parse(submission["files"][0]["name"]).path))
      end

      before do
        published_document.file.blob.update!(filename: filename)
      end

      let(:whitelisted_submission) { described_class.new(planning_application:).call }
      let(:files) { whitelisted_submission[:files] }

      it "shows the correct number of documents" do
        expect(files.count).to eq(planning_application.documents.count)
      end

      it "correctly displays documents" do
        names = files.map { |file| file[:name] }
        expect(names).to include(published_document.file.filename.to_s)
        expect(names).to include("Unpublished document - sensitive")
        expect(names).not_to include(unpublished_document.file.filename.to_s)

        expect(names.count("myPlans.pdf")).to eq(1)
        expect(names.count("Unpublished document - sensitive")).to eq(1)
      end
    end
  end
end
