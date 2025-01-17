# frozen_string_literal: true

require "bops_uploads_helper"

RSpec.describe "Downloading files", show_exceptions: true do
  context "on the uploads subdomain" do
    before do
      host!("uploads.bops.services")
    end

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

  context "on the local authority subdomain" do
    let!(:local_authority) { create(:local_authority, :southwark) }
    let!(:subdomain) { local_authority.subdomain }

    let(:document) { create(:document, planning_application: planning_application) }
    let(:blob) { document.file }
    let(:key) { blob.key }

    before do
      host!("#{subdomain}.bops.services")
    end

    context "when a blob doesn't exist" do
      let(:key) { SecureRandom.base36(28) }

      before do
        get "/files/#{key}"
      end

      it "returns 404 Not Found" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when a blob exists but for another local authority" do
      let(:other_authority) { create(:local_authority, :lambeth) }
      let(:planning_application) { create(:planning_application, local_authority: other_authority) }

      before do
        get "/files/#{key}"
      end

      it "returns 404 Not Found" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when a blob exists for the local authority" do
      let(:planning_application) { create(:planning_application, local_authority: local_authority) }

      before do
        get "/files/#{key}"
      end

      it "returns 302 Found" do
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("http://southwark.bops.services/blobs/#{key}")
      end

      it "sets signed cookies" do
        expect(cookies["CloudFront-Expires"]).to be_present
        expect(cookies["CloudFront-Key-Pair-Id"]).to be_present
        expect(cookies["CloudFront-Signature"]).to be_present
      end

      context "and the redirect is followed" do
        before do
          follow_redirect!
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
          expect(response.content_type).to eq("image/png")
        end
      end
    end
  end
end
