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
    create(:document, :with_file, planning_application:)
  end

  context "as a user who is not logged in" do
    it "User is redirected to login page" do
      visit "/planning_applications/#{planning_application.id}/documents"
      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  context "as an assessor" do
    before do
      sign_in assessor
      visit "/planning_applications/#{planning_application.id}/documents"
    end

    it "Application reference is displayed on page" do
      expect(page).to have_text planning_application.reference
    end

    it "Application address is displayed on page" do
      expect(page).to have_text(planning_application.full_address)
    end

    it "File image is the only one on the page" do
      expect(all("img").count).to eq(1)
    end

    it "Document management page does not contain accordion" do
      expect(page).not_to have_text("Application information")
    end

    it "File image opens in new tab" do
      window = window_opened_by do
        click_link("View in new window")
        sleep 0.5
      end

      within_window(window) do
        expect(page).to have_current_path(/\A\/rails\/active_storage/)
      end
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
          planning_application:,
          file: file2
        )
      end

      it "opens each file in a new tab" do
        visit "/planning_applications/#{planning_application.id}/documents"
        expect(page).to have_selector("h1", text: "Documents")

        window1 = window_opened_by do
          within("tr", text: "File name: proposed-floorplan.png") do
            click_link("View in new window")
            sleep 0.5
          end
        end

        within_window(window1) do
          expect(page).to have_current_path(/proposed-floorplan\.png/)
        end

        window2 = window_opened_by do
          within("tr", text: "File name: proposed-roofplan.png") do
            click_link("View in new window")
            sleep 0.5
          end
        end

        within_window(window1) do
          expect(page).to have_current_path(/proposed-floorplan\.png/)
        end

        within_window(window2) do
          expect(page).to have_current_path(/proposed-roofplan\.png/)
        end
      end
    end

    it "navigates back to the previous page I was on" do
      click_link "Application"

      # Navigate via validation tasks page
      click_link "Check and validate"
      click_button "Documents"
      click_link "Manage documents"
      click_link "Back"
      expect(page).to have_current_path("/planning_applications/#{planning_application.id}/validation/tasks")

      # Navigate via archive document page
      click_button "Documents"
      click_link "Archive"
      click_link "Cancel"
      click_link "Back"
      expect(page).to have_current_path("/planning_applications/#{planning_application.id}/documents/#{document.id}/archive")
    end
  end

  context "when handling invalid documents" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, local_authority: default_local_authority)
    end
    let!(:invalid_document) do
      create(:document, :with_file, planning_application:,
        validated: false, invalidated_document_reason: "Document is invalid")
    end
    let!(:replacement_document_validation_request) do
      create(:replacement_document_validation_request, planning_application:,
        old_document: invalid_document)
    end

    before do
      sign_in assessor
      visit "/planning_applications/#{planning_application.id}/documents"
    end

    it "displays the number of invalid documents at the top of the page" do
      expect(page).to have_text("Invalid documents: 1")
      expect(page).to have_text("Document is invalid")
    end
  end
end
