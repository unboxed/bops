# frozen_string_literal: true

require "rails_helper"
require "zip"

RSpec.describe "Download consultee documents", type: :system, capybara: true do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:planning_application) { create(:planning_application, :pre_application, local_authority:, user:, documents:) }
  let(:consultee) { create(:consultee, :external, email_address: "james.consultee@council.gov.uk", consultation: planning_application.consultation) }
  let(:sgid) { consultee.sgid(expires_in: 1.day, for: "magic_link") }
  let(:reference) { planning_application.reference }
  let(:user) { create(:user) }
  let(:documents) { create_list(:document, 3, :with_file, :consultees) }
  let(:download_path) { Rails.root.join("tmp/downloads", "#{planning_application.reference}.zip") }

  let(:today) do
    Time.zone.today
  end

  before do
    planning_application.consultation.start_deadline
    visit "/consultees/planning_applications/#{reference}?sgid=#{sgid}"
  end

  it "downloads all documents as a zip file" do
    expect(page).to have_current_path("/consultees/planning_applications/#{reference}?sgid=#{sgid}")
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

    pp zip_files
    expect(zip_files).to include(
      "proposed-floorplan.png",
      "proposed-floorplan (1).png",
      "proposed-floorplan (2).png"
    )
  end
end
