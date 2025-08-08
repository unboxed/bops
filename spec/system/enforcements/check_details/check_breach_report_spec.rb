# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check breach report index page", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:case_record) { build(:case_record, local_authority:) }
  let(:enforcement) { create(:enforcement, case_record:) }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in user
    visit "/cases/#{enforcement.case_record.id}/check-breach-report"
  end

  it "displays the correct tasks" do
    within("#case-details") do
      expect(page).to have_content("Case reference #{case_record.id}")
      expect(page).to have_content(enforcement.address)
    end

    within("#dates-details") do
      expect(page).to have_content("Received #{enforcement.received_at.to_date.to_fs}")
    end

    expect(page).to have_link("Check report details")
    expect(page).to have_link("Start investigation")

    expect(page).to have_selector("a", text: "Close the case")
  end
end
