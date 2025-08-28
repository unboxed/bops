# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Documents index page", type: :system do
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
      visit "/planning_applications/#{planning_application.reference}/documents"
      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  context "as an assessor" do
    before do
      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}/documents"
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

    it "File image is downloaded", :capybara do
      new_window = window_opened_by do
        click_link("View in new window")
      end

      within_window(new_window) do
        expect(page).to have_current_path(%r[\Ahttp://planx\.bops\.services:\d{4,5}/blobs/[a-z0-9]{28}\z], url: true)
      end
    end

    context "when there is more than one document" do
      before do
        create(:document,
          planning_application:,
          file: Rack::Test::UploadedFile.new(
            file_fixture("images/proposed-roofplan.png"), "proposed-roofplan/png"
          ))
      end

      it "downloads each file", :capybara do
        visit "/planning_applications/#{planning_application.reference}/documents"
        expect(page).to have_selector("h1", text: "Documents")

        within("tr", text: "File name: proposed-floorplan.png") do
          first_new_window = window_opened_by do
            click_link("View in new window")
          end

          within_window(first_new_window) do
            expect(page).to have_current_path(%r[\Ahttp://planx\.bops\.services:\d{4,5}/blobs/[a-z0-9]{28}\z], url: true)
          end
        end

        within("tr", text: "File name: proposed-roofplan.png") do
          second_new_window = window_opened_by do
            click_link("View in new window")
          end

          within_window(second_new_window) do
            expect(page).to have_current_path(%r[\Ahttp://planx\.bops\.services:\d{4,5}/blobs/[a-z0-9]{28}\z], url: true)
          end
        end

        # confirm that we didn't change tab
        expect(page).to have_selector("h1", text: "Documents")
      end
    end

    it "navigates back to the previous page I was on" do
      click_link "Application"

      # Navigate via validation tasks page
      find("span", text: "Documents").click
      click_link "Manage documents"
      click_link "Back"
      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}")

      # Navigate via archive document page
      find("span", text: "Documents").click
      click_link "Archive"
      click_link "Cancel"
      click_link "Back"
      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/documents/#{document.id}/archive")
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
      visit "/planning_applications/#{planning_application.reference}/documents"
    end

    it "displays the number of invalid documents at the top of the page" do
      expect(page).to have_text("Invalid documents: 1")
      expect(page).to have_text("Document is invalid")
    end
  end
end
