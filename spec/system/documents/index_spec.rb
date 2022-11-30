# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Documents index page" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application,
           local_authority: default_local_authority,
           address_1: "7 Elm Grove")
  end

  let!(:document) do
    create(:document, :with_file, planning_application: planning_application)
  end

  context "as a user who is not logged in" do
    it "User is redirected to login page" do
      visit planning_application_documents_path(planning_application)
      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  context "as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
      click_button "Documents"
      click_link "Manage documents"
    end

    it "Application reference is displayed on page" do
      expect(page).to have_text planning_application.reference
    end

    it "Application address is displayed on page" do
      expect(page).to have_text planning_application.full_address.upcase
    end

    it "File image is the only one on the page" do
      expect(all("img").count).to eq(1)
    end

    it "Document management page does not contain accordion" do
      expect(page).not_to have_text("Application information")
    end

    it "File image opens in new tab" do
      click_link "View in new window"
      page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)

      expect(current_url).to include("/rails/active_storage/")
    end

    context "when there is more than one document" do
      let(:file2) do
        Rack::Test::UploadedFile.new(
          Rails.root.join("spec/fixtures/images/proposed-roofplan.png"),
          "proposed-roofplan/png"
        )
      end

      let!(:document2) do
        create(
          :document,
          planning_application: planning_application,
          file: file2
        )
      end

      it "opens each file in a new tab" do
        visit(planning_application_documents_path(planning_application))

        window1 = window_opened_by do
          row = row_with_content("proposed-floorplan.png")
          within(row) { click_link("View in new window") }
        end

        within_window(window1) do
          expect(current_url).to include("proposed-floorplan.png")
        end

        window2 = window_opened_by do
          row = row_with_content("proposed-roofplan.png")
          within(row) { click_link("View in new window") }
        end

        within_window(window1) do
          expect(current_url).to include("proposed-floorplan.png")
        end

        within_window(window2) do
          expect(current_url).to include("proposed-roofplan.png")
        end
      end
    end
  end

  context "handling invalid documents" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, local_authority: default_local_authority)
    end
    let!(:invalid_document) do
      create(:document, :with_file, planning_application: planning_application,
                                    validated: false, invalidated_document_reason: "Document is invalid")
    end
    let!(:replacement_document_validation_request) do
      create(:replacement_document_validation_request, planning_application: planning_application,
                                                       old_document: invalid_document)
    end

    before do
      sign_in assessor
      visit planning_application_path(planning_application)
      click_button "Documents"
      click_link "Manage documents"
    end

    it "displays the number of invalid documents at the top of the page" do
      expect(page).to have_text("Invalid documents: 1")
      expect(page).to have_text("Document is invalid")
    end
  end
end
