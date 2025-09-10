# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Environmental banner" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }

  before do
    allow(Bops).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

    sign_in assessor
    visit "/"
  end

  it "is not displayed in the production environment" do
    expect(page).not_to have_content "Only process test cases on this version of BOPS"
  end
end
