# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to show document file", type: :request, show_exceptions: true do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) { create(:planning_application, :not_started, local_authority: default_local_authority) }
  let!(:document) { create(:document, :with_file, :public, planning_application: planning_application) }

  describe "data" do
    it "returns a 404 if no planning application" do
      expect do
        get "/api/v1/planning_applications/xxx/documents/#{document.id}"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns a 404 if no document" do
      expect do
        get "/api/v1/planning_applications/#{planning_application.id}/documents/xxx"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "with a document that is not public" do
      let!(:document) { create(:document, :with_file, planning_application: planning_application) }

      it "returns a 404" do
        expect do
          get "/api/v1/planning_applications/#{planning_application.id}/documents/#{document.id}"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a document that has been archived" do
      let!(:document) do
        create(:document, :with_file, :referenced, :archived, planning_application: planning_application)
      end

      it "returns a 404" do
        expect do
          get "/api/v1/planning_applications/#{planning_application.id}/documents/#{document.id}"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "redirects to blob url" do
      get "/api/v1/planning_applications/#{planning_application.id}/documents/#{document.id}"
      expect(response).to redirect_to(rails_blob_path(document.file))
    end
  end
end
