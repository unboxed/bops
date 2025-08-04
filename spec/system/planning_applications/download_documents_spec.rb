# frozen_string_literal: true

require "rails_helper"
require "zip"

RSpec.describe "Downloading planning application documents", type: :system, js: true do
  let!(:default_local_authority) { create(:local_authority, :default) }

  let!(:planning_application) do
    create(
      :planning_application,
      :not_started,
      local_authority: default_local_authority
    )
  end

  let(:file1) { fixture_file_upload("documents/existing-floorplan.png", "image/png", true) }
  let(:file2) { fixture_file_upload("documents/proposed-floorplan.png", "image/png", true) }
  let(:file3) { fixture_file_upload("documents/existing-floorplan-redacted.png", "image/png", true) }

  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:doc1) { create(:document, :floorplan_tags, :public, file: file1, planning_application:, redacted: true) }
  let!(:doc2) { create(:document, file: file2, planning_application:) }
  let!(:doc3) { create(:document, file: file3, planning_application:) }
  let!(:doc4) { create(:document, :checked, file: file3, planning_application:) }

  let(:download_path) { Rails.root.join("tmp/downloads", "#{planning_application.reference}.zip") }

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}/supply_documents"
  end

  context "with attached documents" do
    it "shows the documents in the list" do
      within("table thead tr") do
        expect(page).to have_text("Document name")
        expect(page).to have_text("Date received")
        expect(page).to have_text("Visibility")
        expect(page).to have_text("Redacted")
        expect(page).to have_text("Status")
      end
      within("table tbody tr:nth-child(1)") do
        expect(page).to have_text("existing-floorplan.png")
        expect(page).to have_text("Not started")
        expect(page).to have_text("Public")
        expect(page).to have_text("Redacted")
        expect(page).to have_text("Not started")
        expect(page).to have_text("Roof plan - existing")
        expect(page).to have_text("Roof plan - proposed")
      end
      within("table tbody tr:nth-child(2)") do
        expect(page).to have_text("proposed-floorplan.png")
        expect(page).to have_text("Not started")
        expect(page).not_to have_text("Public")
        expect(page).not_to have_text("Redacted")

        expect(page).to have_text("Not started")
        expect(page).to have_text("No tags added")
      end
      within("table tbody tr:nth-child(3)") do
        expect(page).to have_text("existing-floorplan-redacted.png")
        expect(page).to have_text("Not started")
      end
      within("table tbody tr:nth-child(4)") do
        expect(page).to have_text("existing-floorplan-redacted.png")
        expect(page).to have_text("Checked")
      end
    end

    it "downloads all documents as a zip file" do
      expect(page).to have_content("Submitted documents")
      expect(page).to have_link("Download all documents")

      click_link "Download all documents"
      sleep 3

      expect(File).to exist(download_path)
      zip_files = []
      Zip::File.open(download_path) do |files|
        files.each do |file|
          zip_files << file.name
        end
      end

      expect(zip_files).to include(
        "existing-floorplan.png",
        "proposed-floorplan.png",
        "existing-floorplan-redacted.png",
        "existing-floorplan-redacted (1).png"
      )
    end
  end
end
