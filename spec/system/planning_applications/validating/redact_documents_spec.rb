# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Redact documents" do
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
  let(:file3) { fixture_file_upload("documents/archived-floorplan.png", "image/png", true) }

  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    create(:document, file: file1, planning_application:)
    create(:document, file: file2, planning_application:)
    create(:document, :archived, file: file3, planning_application:)

    sign_in assessor
    visit "/planning_applications/#{planning_application.id}/validation/tasks"
  end

  it "allows assessor to upload redacted documents" do
    click_link "Upload redacted documents"

    expect(page).to have_content("existing-floorplan.png")
    expect(page).to have_content("proposed-floorplan.png")
    expect(page).not_to have_content("archived-floorplan.png")

    within(all(".govuk-table__row")[1]) do
      attach_file("Upload a file", "spec/fixtures/images/existing-floorplan.png")
    end

    click_button "Save and mark as complete"

    expect(page).to have_content "Redacted documents successfully uploaded"

    click_button "Documents"

    expect(page).to have_content "existing-floorplan.png"
    expect(page).to have_content "Public: Yes"
    expect(page).to have_content "Redacted: Yes"

    click_link "Upload redacted documents"

    expect(page).to have_content "existing-floorplan.png"

    find("span", text: "Redact and upload another document").click

    within(:css, ".govuk-table.redacted-document-table") do
      within(all(".govuk-table__row")[1]) do
        attach_file("Upload a file", "spec/fixtures/images/proposed-floorplan.png")
      end
    end

    click_button "Save and mark as complete"

    expect(page).to have_content "Redacted documents successfully uploaded"
  end

  it "shows an error" do
    click_link "Upload redacted documents"

    within(all(".govuk-table__row")[1]) do
      attach_file("Upload a file", "spec/fixtures/images/image.gif")
    end

    click_button "Save and mark as complete"

    expect(page).to have_content "The selected file must be a PDF, JPG or PNG Download original"
  end
end
