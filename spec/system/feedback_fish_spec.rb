# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Feedback fish" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }

  before do
    sign_in assessor
  end

  context "when FEEDBACK_FISH_ID env variable is set" do
    before do
      Rails.configuration.feedback_fish_id = "randomid123"
    end

    it "is displayed with a reference to the user's email" do
      visit root_path

      within find("a[data-feedback-fish][data-feedback-fish-userid='#{assessor.email}']") do
        expect(page).to have_content "feedback"
      end
    end
  end

  context "when FEEDBACK_FISH_ID env variable is not set" do
    before do
      Rails.configuration.feedback_fish_id = nil
    end

    it "is not displayed" do
      visit root_path

      within(".govuk-phase-banner__content") do
        expect(page).not_to have_content "feedback"
      end
    end
  end
end
