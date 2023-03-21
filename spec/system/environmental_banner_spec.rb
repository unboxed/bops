# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Environmental banner" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }

  before do
    sign_in assessor
    visit root_path
  end

  it "is not displayed in the test environment" do
    expect(page).not_to have_content "Only process test cases on this version of BoPS"
  end
end
