# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :system do
  let!(:local_authority) { create(:local_authority, :default) }

  before do
    visit "/reports"
  end

  it "I can view the dashboard" do
    expect(page).to have_current_path("/reports/dashboard")
    expect(page).to have_content("BOPS Reports")
  end
end
