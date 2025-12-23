# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Documents" do
  let!(:current_local_authority) { create(:local_authority, :default) }
  let!(:other_local_authority) { create(:local_authority) }

  let!(:assessor) { create(:user, :assessor, local_authority: current_local_authority) }

  let!(:planning_application) { create(:planning_application, local_authority: other_local_authority) }

  # TODO: add the rest of the actions on documents controller
  it "returns 404 when trying to index documents for a planning application on another local authority" do
    sign_in assessor
    expect do
      get planning_application_documents_path(planning_application)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe "#update redirect behaviour" do
    let!(:planning_application) { create(:planning_application, local_authority: current_local_authority) }
    let!(:document) { create(:document, planning_application:) }

    before { sign_in assessor }

    context "when redirect_to param is provided" do
      it "redirects to the provided path even when validating" do
        redirect_path = "/custom/redirect/path"

        patch planning_application_document_path(planning_application, document),
          params: {validate: "yes", document: {publishable: true, redirect_to: redirect_path}}

        expect(response).to redirect_to(redirect_path)
      end

      it "redirects to the provided path when not validating" do
        redirect_path = "/custom/redirect/path"

        patch planning_application_document_path(planning_application, document),
          params: {document: {publishable: true, redirect_to: redirect_path}}

        expect(response).to redirect_to(redirect_path)
      end
    end

    context "when redirect_to param is not provided" do
      it "redirects to supply_documents when validating" do
        patch planning_application_document_path(planning_application, document),
          params: {validate: "yes", document: {publishable: true}}

        expect(response).to redirect_to(supply_documents_planning_application_path(planning_application))
      end

      it "redirects to documents index when not validating" do
        patch planning_application_document_path(planning_application, document),
          params: {document: {publishable: true}}

        expect(response).to redirect_to(planning_application_documents_path(planning_application))
      end
    end
  end
end
