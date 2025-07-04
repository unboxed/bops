# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enforcement show page", type: :system do
  let(:enforcement) { create(:enforcement) }

  it "has a show page with basic details" do
    visit "/enforcements/#{enforcement.case_record.id}/"
    expect(page).to have_content(enforcement.address)
  end
end
