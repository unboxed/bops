# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::UploadDocumentJob, type: :job do
  let(:arguments) do
    [planning_application, user, url, tags, description]
  end

  let(:user) { create(:api_user) }

  context "when the file downloader isn't configured" do
    let(:planning_application) { create(:planning_application) }
    let(:url) { "https://example.com/path/to/file.pdf" }
    let(:tags) { %w[Site Proposed] }
    let(:description) { "Proposed site plan" }

    before do
      # We need to bypass the validation to simulate
      # existing users without configuration
      user.file_downloader = nil
      user.save!(validate: false)
    end

    it "raises an error" do
      expect {
        described_class.perform_now(*arguments)
      }.to raise_error(BopsApi::Errors::FileDownloaderNotConfiguredError)
    end
  end
end
