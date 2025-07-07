# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enforcement show page", type: :system do
  let(:enforcement) { create(:enforcement) }

  it "has a show page with basic details" do
    visit "/enforcements/#{enforcement.case_record.id}/"
    expect(page).to have_content(enforcement.address)
  end

  context "when assigned to an officer" do
    let(:user) { create(:user) }
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
