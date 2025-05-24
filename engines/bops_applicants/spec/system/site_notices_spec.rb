# frozen_string_literal: true

require "bops_applicants_helper"

RSpec.describe "Site notices" do
  let!(:local_authority) { create(:local_authority, :default) }

  context "when a planning application does not exist" do
    it "returns an error page" do
      expect {
        visit "/planning_applications/00-00000-000/site_notice"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when a planning application is not public" do
    let!(:planning_application) { create(:planning_application, :planning_permission, local_authority:) }
    let!(:site_notice) { create(:site_notice, planning_application:) }
    let!(:reference) { planning_application.reference }

    it "returns an error page" do
      expect {
        visit "/planning_applications/#{reference}/site_notice"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when a planning application is public", js: true do
    let!(:planning_application) { create(:planning_application, :planning_permission, :published, local_authority:) }
    let!(:site_notice) { create(:site_notice, planning_application:) }
    let!(:reference) { planning_application.reference }

    it "allows the user to download the site notice" do
      expect {
        visit "/planning_applications/#{reference}/site_notice"
      }.not_to raise_error

      expect(page).to have_selector("h1", text: "Download site notice")
      expect(page).to have_content(planning_application.address_1)
      expect(page).to have_content(planning_application.reference)
      expect(page).to have_button("Download printable PDF")

      click_button "Download printable PDF"
      expect(downloaded_files).to include("#{reference}-site-notice.pdf")
    end
  end
end
