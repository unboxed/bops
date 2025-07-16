# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enforcement show page", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:case_record) { build(:case_record, local_authority:) }
  let(:enforcement) { create(:enforcement, case_record:) }
  let(:user) { create(:user, local_authority:) }

  before { sign_in user }

  it "has a show page with basic details" do
    visit "/enforcements/#{enforcement.case_record.id}/"
    expect(page).to have_content(enforcement.address)
  end

  it "has a link to the breach report page" do
    visit "/enforcements/#{enforcement.case_record.id}/"
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
      visit "/enforcements/#{enforcement.case_record.id}/"
      expect(page).to have_content("Unassigned")
    end
  end
end
