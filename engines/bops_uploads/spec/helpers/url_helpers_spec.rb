# frozen_string_literal: true

require "bops_uploads_helper"

RSpec.describe "Generating urls" do
  let(:config) { Rails.configuration }
  let(:document) { create(:document) }
  let(:blob) { document.file }
  let(:key) { blob.key }

  before do
    request.headers["HTTP_HOST"] = "southwark.bops.services"
  end

  it "generates urls with the local authority subdomain" do
    expect(helper.uploaded_file_url(blob)).to eq("http://southwark.bops.services/files/#{key}")
  end
end
