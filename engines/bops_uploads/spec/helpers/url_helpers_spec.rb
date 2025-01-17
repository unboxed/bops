# frozen_string_literal: true

require "bops_uploads_helper"

RSpec.describe "Generating urls" do
  let(:config) { Rails.configuration }
  let(:document) { create(:document) }
  let(:blob) { document.file }
  let(:key) { blob.key }

  before do
    request.headers["HTTP_HOST"] = "southwark.bops.services"
    allow(config).to receive(:uploads_base_url).and_return("http://uploads.bops.services")
  end

  context "when use_signed_cookies is false" do
    before do
      allow(config).to receive(:use_signed_cookies).and_return(false)
    end

    it "generates urls with the uploads subdomain" do
      expect(helper.uploaded_file_url(blob)).to eq("http://uploads.bops.services/#{key}")
    end
  end

  context "when use_signed_cookies is true" do
    before do
      allow(config).to receive(:use_signed_cookies).and_return(true)
    end

    it "generates urls with the local authority subdomain" do
      expect(helper.uploaded_file_url(blob)).to eq("http://southwark.bops.services/files/#{key}")
    end
  end
end
