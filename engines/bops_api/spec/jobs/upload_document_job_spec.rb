# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::UploadDocumentJob, type: :job do
  let(:arguments) do
    [planning_application, user, url, tags, description]
  end

  context "when the file downloader isn't configured" do
    let(:planning_application) { create(:planning_application) }
    let(:user) { create(:api_user, file_downloader: nil) }
    let(:url) { "https://example.com/path/to/file.pdf" }
    let(:tags) { %w[Site Proposed] }
    let(:description) { "Proposed site plan" }

    it "raises an error" do
      expect {
        described_class.perform_now(*arguments)
      }.to raise_error(BopsApi::Errors::FileDownloaderNotConfiguredError)
    end
  end
end
