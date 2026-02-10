# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Refunds", type: :system, capybara: true do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :not_started, :pre_application, local_authority: default_local_authority, user: assessor, payment_amount: 400.00)
  end
  let!(:charge) { create(:charge, amount: 200) }
  let!(:payment) { create(:payment, amount: 300) }

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}/charges"
  end

  it "allows me to record a first refund" do
    click_link "Add a refund"
    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/refunds")
    expect(page).to have_selector("h1", text: "Add new refund")
    expect(page).not_to have_content("Refund history")

    fill_in "refund-amount", with: 100.00
    fill_in "Day", with: "2"
    fill_in "Month", with: "6"
    fill_in "Year", with: "2025"

    click_button "Add refund"

    expect(page).to have_content("Enter Payment type")
    expect(page).to have_content("Enter Reason")

    fill_in "refund-payment-type", with: "BACS"
    fill_in "refund-reason", with: "Overpayment"
    fill_in "refund-reference", with: "Ref111"

    click_button "Add refund"
    expect(page).to have_content("Refund created successfully.")
  end

  context "when refunds exist" do
    let!(:refund) { create(:refund, amount: 100.00, planning_application: planning_application) }

    it "shows the refunds in the index table" do
      page.refresh
      within "#fee-calculation" do
        within "#refunds" do
          expect(page).to have_content("£100.00")
        end
      end
    end

    it "allows another refund to be added" do
      within "#fee-calculation" do
        within "#refunds" do
          click_link "Add a refund"
        end
      end
      expect(page).to have_selector("h1", text: "Refunds")
      expect(page).to have_content("Refund history")

      within "#refunds-table" do
        expect(page).to have_content(refund.reason)
        expect(page).to have_content(refund.reference)
      end

      find("summary", text: "Add new refund").click
      within "#refund-toggle" do
        fill_in "refund-amount", with: 50.00
        fill_in "Day", with: "12"
        fill_in "Month", with: "9"
        fill_in "Year", with: "2025"
        fill_in "refund-payment-type", with: "GovPay"
        fill_in "refund-reason", with: "Refund for cancelled meeting"
        fill_in "refund-reference", with: "REF222"
        click_button "Add refund"
      end

      within "#fee-calculation" do
        within "#refunds" do
          expect(page).to have_content("£150.00")
        end
      end
    end

    it "allows me to delete a refund" do
      visit "/planning_applications/#{planning_application.reference}/refunds"
      accept_confirm do
        click_link "Remove"
      end

      expect(page).to have_content("Refund successfully removed.")
      within "#fee-calculation" do
        within "#refunds" do
          expect(page).to have_content("£0.00")
        end
      end
    end
  end
end
