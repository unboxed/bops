# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationRequestHelper, type: :helper do
  let(:planning_application) { create(:planning_application, :invalidated) }
  let(:request) { create(:other_change_validation_request, planning_application: planning_application) }
  let(:document) { create(:document, planning_application: planning_application) }

  describe "#cancel_confirmation_request_url" do
    it "returns the link text and url to the cancel confirmation page for a validation request" do
      url = link_to "Cancel request",
                    cancel_confirmation_planning_application_other_change_validation_request_path(planning_application,
                                                                                                  request)
      expect(cancel_confirmation_request_url(planning_application, request)).to eq(url)
    end
  end

  describe "#cancel_request_url" do
    it "returns the url to the cancel action for a validation request" do
      url = "/planning_applications/#{planning_application.id}/other_change_validation_requests/#{request.id}/cancel"
      expect(cancel_request_url(planning_application, request)).to eq(url)
    end
  end

  describe "#document_url" do
    it "returns the url to the relevant document for an additional document validation request" do
      # rubocop:disable Layout/LineLength
      url = "<a href=\"/planning_applications/#{planning_application.id}/documents/#{document.id}/edit\">proposed-floorplan.png</a>"
      # rubocop:enable Layout/LineLength
      expect(document_url(document)).to eq(url)
    end
  end
end
