# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Charges", type: :system, capybara: true do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :not_started, :pre_application, local_authority: default_local_authority, user: assessor, payment_amount: 400.00)
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
  end

  it "displays the summary page of charges and payments" do
    within("#dates-and-assignment-details") do
      within("#service-charges") do
        click_link "Edit"
      end
    end

    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/charges")
    expect(page).to have_selector("h1", text: "Additional service charges")

    within("#charges-table") do
      expect(page).to have_content("Written advice (initial submission)")
      expect(page).to have_content("£400.00")
      expect(page).not_to have_content("Update")
    end

    expect(page).to have_selector("h2", text: "Fee calculation")
    within("#fee-calculation") do
      within("#initial-fees") do
        expect(page).to have_content("Initial fees")
        expect(page).to have_content("£400.00")
      end

      within("#additional-charges") do
        expect(page).to have_content("Additional charges")
        expect(page).to have_content("£0.00")
      end

      within("#balance-due") do
        expect(page).to have_content("Outstanding balance")
        expect(page).to have_content("£0.00")
      end
    end
  end

  it "adds a charge without a payment" do
    visit "/planning_applications/#{planning_application.reference}/charges"

    click_link "Add new charge or record payment"
    expect(page).to have_selector("h1", text: "Add new charge")

    fill_in "Service description", with: "Meeting- 1 hour"
    click_button "Create charge"

    expect(page).to have_content("Enter Amount")

    fill_in "Amount due", with: 100.00
    within "#payment-due-date" do
      fill_in "Day", with: "12"
      fill_in "Month", with: "10"
      fill_in "Year", with: "2025"
    end
    click_button "Create charge"

    expect(page).to have_content("Charge created successfully")
    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/charges")

    within("#charges-table") do
      expect(page).to have_content("Meeting- 1 hour")
      expect(page).to have_content("£100.00")
      expect(page).to have_content("Update")
    end
  end

  it "allows a charge to be updated with a payment" do
    visit "/planning_applications/#{planning_application.reference}/charges"
    click_link "Add new charge or record payment"
    fill_in "Service description", with: "Meeting- 1 hour"
    fill_in "Amount due", with: 100.00
    click_button "Create charge"

    within("#charges-table") do
      within ".govuk-table__body" do
        within "tr:nth-child(2)" do
          expect(page).to have_content("Meeting- 1 hour")
          expect(page).to have_content("£100.00")
          click_link "Update"
        end
      end
    end

    expect(page).to have_selector("h1", text: "Update charge")

    fill_in "Amount due", with: 150
    fill_in "Amount paid", with: 100
    within "#payment-date-received" do
      fill_in "Day", with: "12"
      fill_in "Month", with: "10"
      fill_in "Year", with: "2025"
    end
    fill_in "Payment type", with: "GovPay"
    fill_in "Reference", with: "REF-123"

    click_button "Save changes"

    expect(page).to have_content("Charge updated successfully.")
    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/charges")

    within("#additional-charges") do
      expect(page).to have_content("£150.00")
    end

    within("#amount-paid") do
      expect(page).to have_content("£500.00")
    end

    within("#balance-due") do
      expect(page).to have_content("Outstanding balance")
      expect(page).to have_content("£50.00")
    end
  end
end
