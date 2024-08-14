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
    create(:document, :floorplan_tags, file: file1, planning_application:)
    create(:document, file: file2, planning_application:)
    create(:document, :archived, file: file3, planning_application:)

    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
  end

  it "allows an assessor to upload redacted documents" do
    click_link "Upload redacted documents"

    expect(page).to have_content("existing-floorplan.png")
    expect(page).to have_content("proposed-floorplan.png")
    expect(page).not_to have_content("archived-floorplan.png")

    within(all(".govuk-table__row")[1]) do
      attach_file("Upload a file", "spec/fixtures/files/documents/existing-floorplan-redacted.png")
    end

    click_button "Save and come back later"

    expect(page).to have_content "Redacted documents successfully uploaded"

    within("#confirm-documents-tasks") do
      expect(page).to have_selector("li:nth-of-type(3)", text: "Upload redacted documents")
      expect(page).to have_selector("li:nth-of-type(3) .govuk-tag", text: "In progress")
    end

    click_link "Upload redacted documents"

    expect(page).to have_content "existing-floorplan.png"

    find("span", text: "Redact and upload another document").click

    within(:css, ".govuk-table.redacted-document-table") do
      within(all(".govuk-table__row")[1]) do
        attach_file("Upload a file", "spec/fixtures/files/documents/proposed-floorplan-redacted.png")
      end
    end

    click_button "Save and mark as complete"

    expect(page).to have_content "Redacted documents successfully uploaded"

    within("#confirm-documents-tasks") do
      expect(page).to have_selector("li:nth-of-type(3)", text: "Upload redacted documents")
      expect(page).to have_selector("li:nth-of-type(3) .govuk-tag", text: "Completed")
    end

    click_link "Tag and validate supplied documents"

    within("#check-tag-documents-tasks") do
      expect(page).to have_selector("li:nth-of-type(3)", text: "existing-floorplan-redacted.png")
      expect(page).to have_selector("li:nth-of-type(3) .govuk-tag", text: "Valid")

      expect(page).to have_selector("li:nth-of-type(4)", text: "proposed-floorplan-redacted.png")
      expect(page).to have_selector("li:nth-of-type(4) .govuk-tag", text: "Valid")
    end

    click_link "existing-floorplan-redacted.png"

    expect(page).to have_checked_field "Roof plan - existing"
    expect(page).to have_checked_field "Roof plan - proposed"
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
