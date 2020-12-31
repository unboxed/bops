# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API request to list planning applications", type: :request, show_exceptions: true do
  let!(:planning_application) { create(:planning_application, :not_started) }
  let!(:document) { create(:document, :with_file, planning_application: planning_application) }

  describe "data" do
    it "returns a 404 if no planning application" do
      expect {
        get "/api/v1/planning_applications/xxx/documents/#{document.id}"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns a 404 if no document" do
      expect {
        get "/api/v1/planning_applications/#{planning_application.id}/documents/xxx"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "redirects to blob url" do
      get "/api/v1/planning_applications/#{planning_application.id}/documents/#{document.id}"
      expect(response).to redirect_to(rails_blob_path(document.file))
    end
  end
end
