# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Application::DocumentsService, type: :job do
  let(:arguments) do
    [planning_application, user, url, tags, description]
  end

  let(:planning_application) { create(:planning_application) }
  let(:user) { create(:api_user) }
  let(:url) { "https://example.com/path/to/file.pdf" }
  let(:tags) { %w[sitePlan.proposed] }
  let(:description) { "Proposed site plan" }
  let(:files) { [{"name" => url, "type" => ["something"]}] }

  context "when the tags are empty" do
    before do
      stub_request(:get, url).to_return(status: 200, body: "")
    end

    it "does not raise an error" do
      expect {
        described_class.new(planning_application:, user:, files:).call!
      }.not_to raise_error
    end
  end
end
