# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enforcement show page", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:case_record) { build(:case_record, local_authority:) }
  let!(:enforcement) { create(:enforcement, case_record:) }
  let(:user) { create(:user, local_authority:) }
  let!(:task) { create(:task, parent: case_record, section: "Check", name: "Test task 1", slug: "test-task-1") }
  let!(:task2) { create(:task, parent: case_record, section: "Check", name: "Test task 2", slug: "test-task-2") }
  let!(:task3) { create(:task, parent: case_record, section: "Investigate", name: "Test task 3", slug: "test-task-3") }

  before do
    sign_in(user)
    visit "/enforcements/#{enforcement.case_record.id}/"
  end

  it "has a show page with basic details" do
    expect(page).to have_content(enforcement.address)
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
        expect(lis[0]).to have_text("Check breach report")
        expect(lis[1]).to have_text(task.name)
        expect(lis[2]).to have_text(task2.name)
      end

      expect(h2s[1]).to have_text("Investigate")
      within("#Investigate-section") do
        lis = all("li", count: 2)
        expect(lis[0]).to have_text("Investigate and decide")
        expect(lis[1]).to have_text(task3.name)
      end

      expect(h2s[2]).to have_text("Review")
      within("#Review-section") do
        expect(page).to have_selector("li", text: "Review recommendation")
      end

      expect(h2s[4]).to have_text("Appeal")
      within("#Appeal-section") do
        lis = all("li", count: 1)
        expect(lis[0]).to have_text("Process an appeal")
      end
    end
  end
end
