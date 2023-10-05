# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Google Tag Manager" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }

  before do
    sign_in assessor
  end

  context "when GOOGLE_TAG_MANAGER_ID env variable is set" do
    before do
      Rails.configuration.google_tag_manager_id = "GTM-12345678"
    end

    it "includes the Google Tag Manager script and noscript" do
      visit root_path

      within("head") do
        expect(page).to have_css("script[nonce]", text: /gtm\.start/)
      end

      within("body") do
        expect(page).to have_css("noscript")
        expect(page.body).to include("https://www.googletagmanager.com/ns.html?id=GTM-12345678")
      end
    end
  end

  context "when GOOGLE_TAG_MANAGER_ID env variable is not set" do
    before do
      Rails.configuration.google_tag_manager_id = nil
    end

    it "does not include Google Tag Manager" do
      visit root_path

      expect(page).not_to have_css("script[nonce]", text: /gtm\.start/)
      expect(page).not_to have_css("noscript")
    end
  end
end
