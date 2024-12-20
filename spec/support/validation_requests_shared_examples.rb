# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "ValidationRequests" do |_klass, request_type|
  let!(:current_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) { create(:planning_application, :invalidated, local_authority: current_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: current_local_authority) }
  let(:request) { create(request_type, planning_application:) }
  let(:document) { create(:document, planning_application:) }

  before do
    allow(LocalAuthority).to receive(:find_by).and_return(current_local_authority)

    sign_in assessor
  end

  describe "#cancel_confirmation" do
    describe "when the validation request can be cancelled" do
      it "responds with a 200" do
        params = {
          id: request.id,
          planning_application_reference: request.planning_application.reference
        }

        get(:cancel_confirmation, params:)

        expect(response).to be_ok
      end
    end

    describe "when the validation request can not be cancelled" do
      let!(:request) { create(request_type, :cancelled, planning_application:) }

      it "responds with a 404" do
        params = {
          id: request.id,
          planning_application_reference: request.planning_application.reference
        }

        get(:cancel_confirmation, params:)

        expect(response).to be_not_found
      end
    end
  end

  describe "#cancel" do
    describe "when the validation request can be cancelled" do
      it "successfully redirects to the validation requests index page" do
        params = {
          id: request.id,
          planning_application_reference: request.planning_application.reference,
          "#{request_type}": {cancel_reason: "my mistake"}
        }

        patch(:cancel, params:)

        expect(response).to redirect_to planning_application_validation_validation_requests_path(planning_application)
      end
    end

    describe "when the validation request can not be cancelled" do
      it "with no cancel reason it redirects back to the cancel_confirmation page" do
        params = {
          id: request.id,
          planning_application_reference: request.planning_application.reference,
          "#{request_type}": {cancel_reason: ""}
        }

        patch(:cancel, params:)

        expect(response).to redirect_to send(:"cancel_confirmation_planning_application_validation_#{request_type}_path",
          planning_application, request)
      end

      it "when state is not pending/open it redirects back to the cancel_confirmation page" do
        request.update!(state: "cancelled", cancel_reason: "my mistake")

        params = {
          id: request.id,
          planning_application_reference: request.planning_application.reference,
          "#{request_type}": {cancel_reason: request.cancel_reason}
        }

        patch(:cancel, params:)

        expect(response).to redirect_to send(:"cancel_confirmation_planning_application_validation_#{request_type}_path",
          planning_application, request)
      end
    end
  end

  describe "#new" do
    context "when planning application is closed or cancelled" do
      before do
        request
        planning_application.close!
      end

      it "responds with a 403" do
        params = {
          planning_application_reference: request.planning_application.reference
        }

        get(:new, params:)

        expect(response).to be_forbidden
      end
    end

    context "when planning application is not closed or cancelled" do
      it "responds with a 200" do
        params = {
          planning_application_reference: planning_application.reference
        }

        if request_type == "replacement_document_validation_request"
          request.old_document = document
          params[:document] = request.old_document_id
        end

        get(:new, params:)

        expect(response).to be_ok
      end
    end
  end
end
