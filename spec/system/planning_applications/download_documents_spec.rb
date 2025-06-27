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

  let!(:doc1) { create(:document, :floorplan_tags, file: file1, planning_application:) }
  let!(:doc2) { create(:document, file: file2, planning_application:) }
  let!(:doc3) { create(:document, file: file3, planning_application:) }
  let!(:doc4) { create(:document, file: file3, planning_application:) }

  let(:download_path) { Rails.root.join("tmp/downloads", "#{planning_application.reference}.zip") }

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}/supply_documents"
  end

  context "with attached documents" do
    it "downloads all documents as a zip file" do
      expect(page).to have_content("Check supplied documents")
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
