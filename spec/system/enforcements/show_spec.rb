# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enforcement show page", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:submission) do
    create(
      :submission,
      local_authority: local_authority,
      request_body: json_fixture_api("examples/odp/v0.7.5/enforcement/breach.json")
    )
  end

  let(:proposal_details) do
    [
      {
        question: "Has work already started?",
        responses: [{value: "Yes"}],
        metadata: {section_name: "About the property"}
      },
      {
        question: "Is ther existing panning permission?",
        responses: [{value: "No"}],
        metadata: {section_name: "group_1"}
      }
    ]
  end
  let!(:case_record) { build(:case_record, local_authority:, submission: submission) }
  let!(:document) { create(:document, :with_tags, case_record:) }
  let!(:document_1) { create(:document, :with_file, case_record:) }
  let!(:enforcement) { create(:enforcement, case_record:, proposal_details: proposal_details) }
  let(:user) { create(:user, local_authority:) }
  let!(:task) { create(:task, parent: case_record, section: "Check", name: "Test task 1", slug: "test-task-1") }
  let!(:task2) { create(:task, parent: case_record, section: "Check", name: "Test task 2", slug: "test-task-2") }
  let!(:task3) { create(:task, parent: case_record, section: "Investigate", name: "Test task 3", slug: "test-task-3") }

  before do
    enforcement.update(proposal_details: proposal_details)

    sign_in(user)
    visit "/enforcements/#{enforcement.case_record.id}/"
  end

  it "has a show page with basic details" do
    expect(page).to have_content(enforcement.address)
  end
  context "within the accordion" do
    it "has the correct information in the accordion", capybara: true do
      within(".govuk-accordion") do
        within("#breach-report-section") do
          find("button", text: "Breach report").click

          within("tbody") do
            expect(page).to have_text("Has work already started?")
          end
        end

        within("#complainant-details-section") do
          find("button", text: "Complainant details").click

          within("tbody") do
            expect(page).to have_text(enforcement.complainant.email)
            expect(page).to have_text(enforcement.complainant.address)
          end
        end
      end
    end

    it "allows me to see all documents", :capybara do
      within(".govuk-accordion") do
        within("#documents-and-photos-section") do
          find("button", text: "Documents and Photos").click

          within("thead") do
            expect(page).to have_text("Document name")
            expect(page).to have_text("Date received")
          end

          within("tbody") do
            rows = page.all(".govuk-table__row")
            expect(rows.size).to eq(2)

            within(rows[0]) do
              expect(page).to have_link("#{document.name} (opens in new tab)")
              expect(page).to have_selector(".govuk-tag", text: "Elevations - proposed")
            end

            within(rows[1]) do
              expect(page).to have_link("#{document_1.name} (opens in new tab)")
              expect(page).not_to have_selector(".govuk-tag", text: "Elevations - proposed")
            end
          end
        end
      end
    end
  end

  it "has a link to the breach report page" do
    click_link "Check breach report"
    expect(page).to have_selector("h1", text: "Check breach report")
  end

  context "when assigned to an officer" do
    before { enforcement.case_record.update!(user:) }

    it "shows the assigned officer" do
      visit "/enforcements/#{enforcement.case_record.id}/"
      expect(page).to have_content("Assigned to: " + user.name)
    end
  end

  context "when not assigned to an officer" do
    it "shows no assigned officer" do
      expect(page).to have_content("Unassigned")
    end
  end

  it "shows the correct grouping of tasks", capybara: true do
    within("#enforcement-tasks") do
      expect(page).to have_selector("h2", count: 6)
      h2s = all("h2", count: 6)

      expect(h2s[0]).to have_text("Check")
      within("#Check-section") do
        lis = all("li", count: 3)
        expect(lis[0]).to have_link("Check breach report")
        expect(lis[1]).to have_link(task.name)
        expect(lis[2]).to have_link(task2.name)
      end

      expect(h2s[1]).to have_text("Investigate")
      within("#Investigate-section") do
        lis = all("li", count: 2)
        expect(lis[0]).to have_link("Investigate and decide")
        expect(lis[1]).to have_link(task3.name)
      end

      expect(h2s[2]).to have_text("Review")
      within("#Review-section") do
        lis = all("li", count: 1)
        expect(lis[0]).to have_link("Review recommendation")
      end

      expect(h2s[4]).to have_text("Appeal")
      within("#Appeal-section") do
        lis = all("li", count: 1)
        expect(lis[0]).to have_link("Process an appeal")
      end
    end
  end
end
