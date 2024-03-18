# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::UploadDocumentJob, type: :job do
  let(:arguments) do
    [planning_application, user, url, tags, description]
  end

  let(:planning_application) { create(:planning_application) }
  let(:user) { create(:api_user) }
  let(:url) { "https://example.com/path/to/file.pdf" }
  let(:tags) { %w[sitePlan.proposed] }
  let(:description) { "Proposed site plan" }

  context "when the file downloader isn't configured" do
    let(:user) { create(:api_user, file_downloader: nil) }

    it "raises an error" do
      expect {
        described_class.perform_now(*arguments)
      }.to raise_error(BopsApi::Errors::FileDownloaderNotConfiguredError)
    end
  end

  context "when the tags are empty" do
    before do
      stub_request(:get, url).to_return(status: 200, body: "")
    end

    let(:tags) { [nil] }

    it "does not raise an error" do
      expect {
        described_class.perform_now(*arguments)
      }.not_to raise_error
    end
  end
end
