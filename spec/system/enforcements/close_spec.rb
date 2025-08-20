# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enforcement close page", type: :system do
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

  it "can be closed", :capybara do
    click_link "Close case"
    choose "Other"
    fill_in "Reason", with: "Because I want to"
    fill_in "Reason for closing", with: "Words words words."
    click_button "Close case"

    expect(page).to have_content("Case successfully closed")
    enforcement.reload
    expect(enforcement.status).to eq("closed")
    expect(enforcement.closed_reason).to eq("Because I want to")
  end
end
