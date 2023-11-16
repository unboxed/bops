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

  let!(:document1) do
    create(:document, :with_file, planning_application:)
  end

  let!(:document2) do
    create(:document, :with_file, planning_application:)
  end

  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    sign_in assessor
    visit planning_application_validation_tasks_path(planning_application)
  end

  it "allows assessor to upload redacted documents" do
    click_link "Upload redacted documents"

    expect(page).to have_content(document1.name)
    expect(page).to have_content(document2.name)

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
