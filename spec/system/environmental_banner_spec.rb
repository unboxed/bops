# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Environmental banner" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("production")

    sign_in assessor
    visit "/"
  end

  it "is not displayed in the production environment" do
    expect(page).not_to have_content "Only process test cases on this version of BOPS"
  end
end
