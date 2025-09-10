# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Submissions", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:admin) { create(:user, :administrator, local_authority:) }

  before { sign_in(admin) }

  it "shows paginated submissions and allows viewing details" do
    create_list(:submission, 4, local_authority:)
    create_list(:submission, 4, :failed, local_authority:)
    create_list(:submission, 4, :completed, local_authority:)
    submissions = local_authority.submissions.by_created_at_desc
    visit "/admin/submissions"

    expect(page).to have_selector("h1.govuk-heading-l", text: "Submissions")

    within("#submissions thead tr") do
      %w[Reference Source Status Created\ at Started\ at Completed\ at Failed\ at Actions].each do |heading|
        expect(page).to have_content(heading)
      end
    end

    expect(page).to have_selector("#submissions tbody tr", count: 10)

    submissions.first(10).each do |submission|
      within("#submission_#{submission.id}") do
        cells = all("td")
        expect(cells[0].text).to eq(submission.application_reference)
        expect(cells[1].text).to eq(submission.source)
        expect(cells[2].text).to eq(submission.status)
        expect(cells[3].text).to eq(submission.created_at.to_fs)
        expect(cells[4].text).to eq(submission.started_at&.to_fs.to_s)
        expect(cells[5].text).to eq(submission.completed_at&.to_fs.to_s)
        expect(cells[6].text).to eq(submission.failed_at&.to_fs.to_s)
        expect(cells[7]).to have_link("View", href: "/admin/submissions/#{submission.id}")
      end
    end

    within(".govuk-pagination") do
      expect(page).to have_selector(".govuk-pagination__item", count: 2)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "1")
      expect(page).not_to have_link("Previous")
      expect(page).to have_link("Next", href: "/admin/submissions?page=2")
    end

    click_link "Next"
    expect(page).to have_current_path("/admin/submissions?page=2")
    expect(page).to have_selector("#submissions tbody tr", count: 2)
  end

  context "when viewing an individual submission" do
    let(:submission) do
      create(
        :submission,
        request_body: {
          "applicationRef" => "PT-10087984",
          "documentLinks" => [
            {
              "documentName" => "PT-10087984.zip",
              "documentLink" => zip
            }
          ]
        },
        local_authority:
      )
    end

    let(:zip) { file_fixture_submissions("applications/PT-10087984.zip") }

    before do
      sign_in(admin)

      stub_request(:get, submission.document_link_urls.first)
        .to_return(
          status: 200,
          body: File.binread(zip),
          headers: {"Content-Type" => "application/zip"}
        )

      BopsSubmissions::ZipExtractionService.new(submission: submission).call
      submission.reload
    end

    it "shows all the submission details, payload and documents" do
      visit "/admin/submissions"
      within("#submission_#{submission.id}") do
        click_link "View"
      end

      expect(page).to have_selector("h1.govuk-heading-l", text: "Submission")

      within(".govuk-summary-list") do
        {
          "Reference" => submission.application_reference,
          "Source" => submission.source,
          "Status" => submission.status,
          "Created at" => submission.created_at.to_fs,
          "Started at" => submission.started_at&.to_fs.to_s,
          "Completed at" => submission.completed_at&.to_fs.to_s,
          "Failed at" => submission.failed_at&.to_fs.to_s,
          "External UUID" => submission.external_uuid
        }.each do |label, value|
          expect(page).to have_selector("dt", text: label)
          expect(page).to have_selector("dd", text: value)
        end
      end

      %w[Request\ Body Request\ Headers Application\ payload Other\ files].each do |summary|
        expect(page).to have_selector(".govuk-details__summary-text", text: summary)
      end

      find(".govuk-details__summary-text", text: "Request Body").click
      within(".govuk-details", text: "Request Body") do
        expect(page).to have_content('"applicationRef"')
        expect(page).to have_content('"documentLinks"')
      end

      find(".govuk-details__summary-text", text: "Request Headers").click
      within(".govuk-details", text: "Request Headers") do
        expect(page).to have_content('"Content-Type"')
      end

      find(".govuk-details__summary-text", text: "Application payload").click
      within(".govuk-details", text: "Application payload") do
        raw = find("pre").text
        parsed = JSON.parse(raw)

        expect(parsed.keys).to include(
          "applicationData",
          "applicationHeader",
          "documentList",
          "schemaVersion"
        )

        expect(parsed["applicationData"].keys).to include(
          "applicant",
          "agent",
          "siteLocation"
        )
      end

      find(".govuk-details__summary-text", text: "Other files").click
      within(".govuk-details", text: "Other files") do
        expect(page).to have_content("Application.xml")
      end

      expect(page).to have_selector("h3.govuk-heading-s", text: "Submission documents")

      docs = submission.documents.order(:created_at)
      expect(docs.length).to eq(9)
      within("table") do
        expect(page).to have_content("Filename")
        expect(page).to have_content("Uploaded At")
        expect(page).to have_content("View")

        all("tbody tr").each_with_index do |tr, idx|
          doc = docs[idx]
          cols = tr.all("td").map(&:text)

          expect(cols[0]).to eq(doc.metadata["filename"])
          expect(cols[1]).to eq(doc.created_at.to_fs)
          expect(tr).to have_link(
            "View (opens in new tab)"
          )
        end
      end
    end
  end

  context "when a submission has been processed into a planning application" do
    let!(:application_type_pp) { create(:application_type, :planning_permission, local_authority:) }
    let(:submission) do
      create(
        :submission,
        request_body: {
          "applicationRef" => "PT-10087984",
          "documentLinks" => [
            {
              "documentName" => "PT-10087984.zip",
              "documentLink" => zip_path
            }
          ]
        },
        local_authority:
      )
    end

    let(:zip_path) { file_fixture_submissions("applications/PT-10087984.zip") }

    before do
      stub_request(:get, submission.document_link_urls.first)
        .to_return(
          status: 200,
          body: File.binread(zip_path),
          headers: {"Content-Type" => "application/zip"}
        )

      BopsSubmissions::ZipExtractionService.new(submission:).call
      BopsSubmissions::Application::PlanningPortalCreationService.new(submission:).call!
      submission.reload
    end

    it "displays the Planning Application section with correct summary and documents" do
      visit "/admin/submissions"
      within("#submission_#{submission.id}") do
        click_link "View"
      end

      expect(page).to have_selector("h1.govuk-heading-l", text: "Submission")
      expect(page).to have_selector("hr.govuk-section-break--visible")

      planning_application = submission.planning_application
      expect(page).to have_selector("h2.govuk-heading-m", text: "Planning Application")

      within(".planning-applications-summary-list") do
        expect(page).to have_selector("dt", text: "Reference")
        expect(page).to have_selector("dd", text: planning_application.reference)

        expect(page).to have_selector("dt", text: "Status")
        expect(page).to have_selector("dd", text: "Not started")

        expect(page).to have_selector("dt", text: "Received at")
        expect(page).to have_selector("dd", text: planning_application.received_at.to_fs)

        expect(page).to have_selector("dt", text: "Local Authority")
        expect(page).to have_selector("dd", text: planning_application.local_authority.council_name)

        expect(page).to have_selector("dt", text: "Application Type")
        expect(page).to have_selector("dd", text: planning_application.application_type.human_name)
      end

      expect(page).to have_selector("h3.govuk-heading-s", text: "Planning Application documents")

      documents = planning_application.documents.order(:created_at)

      within("#planning-application-documents-table") do
        expect(page).to have_content("Filename")
        expect(page).to have_content("Uploaded At")
        expect(page).to have_content("View")

        all("tbody tr").each_with_index do |tr, idx|
          doc = documents[idx]
          cols = tr.all("td").map(&:text)

          expect(cols[0]).to eq(doc.file.filename.to_s)
          expect(cols[1]).to eq(doc.created_at.to_fs)
          expect(tr).to have_link("View (opens in new tab)")
        end
      end
    end
  end

  context "when a submission has been processed into an enforcement case" do
    let!(:submission) { create(:submission, :enforcement, local_authority:) }

    it "shows the PlanX enforcement in the index and lets me view its request body and headers" do
      visit "/admin/submissions"

      within("#submission_#{submission.id}") do
        expect(page).to have_content("PlanX")
        click_link "View"
      end

      expect(page).to have_selector(".govuk-details__summary-text", text: "Request Body")
      expect(page).to have_selector(".govuk-details__summary-text", text: "Request Headers")

      find(".govuk-details__summary-text", text: "Request Body").click
      within(".govuk-details", text: "Request Body") do
        raw = find("pre").text
        parsed = JSON.parse(raw)

        expect(parsed.keys).to include(
          "data",
          "metadata",
          "responses"
        )
      end

      find(".govuk-details__summary-text", text: "Request Headers").click
      within(".govuk-details", text: "Request Headers") do
        expect(page).to have_content('"Content-Type"')
      end
    end
  end
end
