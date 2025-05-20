# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Submissions", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:admin) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(admin)
  end

  it "shows paginated submissions and allows viewing details" do
    submissions = create_list(:submission, 12, local_authority:)
    visit "/admin/submissions"
    expect(page).to have_selector("h1", text: "Submissions")

    # Table head
    within("#submissions thead") do
      expect(page).to have_content("Reference")
      expect(page).to have_content("Source")
      expect(page).to have_content("Status")
      expect(page).to have_content("Created at")
      expect(page).to have_content("Actions")
    end

    # Table body
    expect(page).to have_selector("#submissions tbody tr", count: 10)
    within("#submissions tbody") do
      submissions.first(10).each do |submission|
        expect(page).to have_content(submission.application_reference)
        expect(page).to have_content(submission.source)
        expect(page).to have_content(submission.status)
        expect(page).to have_content(submission.created_at.to_fs)
        expect(page).to have_link("View")
      end
    end

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 2)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "1")
      expect(page).to have_no_link("Previous")
      expect(page).to have_link("Next", href: "/admin/submissions?page=2")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/submissions?page=2")
    expect(page).to have_selector("#submissions tbody tr", count: 2)

    within("#submission_#{submissions.first.id}") do
      click_link("View")
    end

    expect(page).to have_selector("h1", text: "Submission")

    within(".govuk-summary-list") do
      submission = submissions.last
      expect(page).to have_content("Reference")
      expect(page).to have_content(submission.application_reference)
      expect(page).to have_content("Source")
      expect(page).to have_content(submission.source)
      expect(page).to have_content("Status")
      expect(page).to have_content(submission.status)
      expect(page).to have_content("Created at")
      expect(page).to have_content(submission.created_at.to_fs)
      expect(page).to have_content("External UUID")
      expect(page).to have_content(submission.external_uuid)
    end

    expect(page).to have_selector(".govuk-details__summary-text", text: "Request Body")
    expect(page).to have_selector(".govuk-details__summary-text", text: "Request Headers")
    find(".govuk-details__summary-text", text: "Request Body").click
    within(".govuk-details", text: "Request Body") do
      expect(page).to have_content('"applicationRef": "10027719"')
      expect(page).to have_content('"applicationState": "Submitted"')
      expect(page).to have_content('"documentName": "PT-10027719.zip"')
      expect(page).to have_content('"documentLink": "https://example.com/PT-10027719.zip"')
      expect(page).to have_content('"documentType": "application/x-zip-compressed"')
      expect(page).to have_content('"updated": false')
    end

    find(".govuk-details__summary-text", text: "Request Headers").click
    within(".govuk-details", text: "Request Headers") do
      expect(page).to have_content('"Content-Type": "application/json"')
    end
  end
end
