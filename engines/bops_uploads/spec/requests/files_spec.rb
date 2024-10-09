# frozen_string_literal: true

require "bops_uploads_helper"

RSpec.describe "Downloading files", show_exceptions: true do
  context "when a blob exists" do
    let(:document) { create(:document) }
    let(:blob) { document.file }
    let(:key) { blob.key }
    let(:path) { blob.service.path_for(blob.key) }

    it "returns 200 OK" do
      get "/#{key}"
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("image/png")
    end

    context "but the file is missing" do
      before do
        File.unlink(path)
      end

      it "returns 404 Not Found" do
        get "/#{key}"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "when a blob doesn't exist" do
    let(:key) { SecureRandom.base36(28) }

    it "returns 404 Not Found" do
      get "/#{key}"
      expect(response).to have_http_status(:not_found)
    end
  end
end
