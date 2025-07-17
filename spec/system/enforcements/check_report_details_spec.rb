# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check breach report", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:case_record) { build(:case_record, local_authority:) }
  let(:enforcement) { create(:enforcement, case_record:) }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in user
    visit "/enforcements/#{enforcement.case_record.id}/report"
  end

  it "shows the relevant report details" do
    click_link "Check report details"

    expect(page).to have_content("Check report details")
    expect(page).to have_content("Quick close")
    expect(page).to have_content("Is this case urgent?")
  end

  it "allows me to mark a case as urgent" do
    expect(page).not_to have_content("urgent")
    click_link "Check report details"
    check "Select here if the case is urgent"

    click_button "Save and mark complete"
    expect(page).to have_content("Enforcement case updated")
    expect(page).to have_content("urgent")
  end
end
