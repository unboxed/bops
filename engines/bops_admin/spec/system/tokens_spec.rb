# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API Tokens", :capybara do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }
  let(:last_token) { ApiUser.last }

  around do |example|
    travel_to("2024-10-22T10:30:00Z") { example.run }
  end

  before do
    sign_in(user)

    create(:api_user, :planx, name: "Active Token", last_used_at: 1.week.ago)
    create(:api_user, :planx, name: "Revoked Token", last_used_at: 2.weeks.ago, revoked_at: 1.week.ago)
  end

  it "shows a list of active tokens" do
    visit "/admin/tokens#active"

    expect(page).to have_selector("h1", text: "API tokens")
    expect(page).to have_selector("a[aria-selected=true]", text: "Active")

    within "#active table" do
      within "thead tr:nth-child(1)" do
        expect(page).to have_selector("th:nth-child(1)", text: "Name")
        expect(page).to have_selector("th:nth-child(2)", text: "Service")
        expect(page).to have_selector("th:nth-child(3)", text: "Last used at")
      end

      within "tbody tr:nth-child(1)" do
        expect(page).to have_selector("td:nth-child(1)", text: "Active Token")
        expect(page).to have_selector("td:nth-child(2)", text: "PlanX")
        expect(page).to have_selector("td:nth-child(3)", text: "Tue, 15 Oct 2024 11:30:00 +0100")
      end
    end
  end

  it "shows a list of revoked tokens" do
    visit "/admin/tokens#revoked"

    expect(page).to have_selector("h1", text: "API tokens")
    expect(page).to have_selector("a[aria-selected=true]", text: "Revoked")

    within "#revoked table" do
      within "thead tr:nth-child(1)" do
        expect(page).to have_selector("th:nth-child(1)", text: "Name")
        expect(page).to have_selector("th:nth-child(2)", text: "Service")
        expect(page).to have_selector("th:nth-child(3)", text: "Last used at")
        expect(page).to have_selector("th:nth-child(4)", text: "Revoked at")
      end

      within "tbody tr:nth-child(1)" do
        expect(page).to have_selector("td:nth-child(1)", text: "Revoked Token")
        expect(page).to have_selector("td:nth-child(2)", text: "PlanX")
        expect(page).to have_selector("td:nth-child(3)", text: "Tue, 08 Oct 2024 11:30:00 +0100")
        expect(page).to have_selector("td:nth-child(4)", text: "Tue, 15 Oct 2024 11:30:00 +0100")
      end
    end
  end

  it "allows a token to be revoked" do
    visit "/admin/tokens"

    expect(page).to have_selector("h1", text: "API tokens")
    expect(page).to have_selector("a[aria-selected=true]", text: "Active")

    within "#active table" do
      within "tbody tr:nth-child(1)" do
        click_link "Edit"
      end
    end

    expect(page).to have_selector("h1", text: "Edit API token")

    accept_confirm(text: "Are you sure you want to revoke this API token?") do
      click_link("Revoke")
    end

    expect(page).to have_selector("[role=alert] p", text: "API token successfully revoked")

    within "#active table" do
      within "tbody tr:nth-child(1)" do
        expect(page).to have_selector("td:nth-child(1)", text: "There are no active API tokens")
      end
    end

    within "#revoked table" do
      within "tbody tr:nth-child(1)" do
        expect(page).to have_selector("td:nth-child(1)", text: "Active Token")
        expect(page).to have_selector("td:nth-child(4)", text: "Tue, 22 Oct 2024 11:30:00 +0100")
      end
    end
  end

  context "with no download authentication" do
    it "allows a token to be created" do
      visit "/admin/tokens"

      expect(page).to have_selector("h1", text: "API tokens")
      expect(page).to have_selector("a[aria-selected=true]", text: "Active")

      click_link "Add API token"
      expect(page).to have_selector("h1", text: "Add API token")

      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "Please enter a name for this API token")

      fill_in "Name", with: "Active Token"

      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "That name is already in use by an active token")

      fill_in "Name", with: "New Token"
      fill_in "Service", with: "Service Name"
      check "comment:read"

      click_button "Save"
      expect(page).to have_current_path("/admin/tokens")
      expect(page).to have_selector("h1", text: "API token generated")
      expect(page).to have_selector("div.govuk-panel__body strong", text: /\Abops_[a-zA-Z0-9]{36}[-_a-zA-Z0-9]{6}\z/)

      click_link "Return to the list of API tokens"
      expect(page).to have_selector("h1", text: "API tokens")
      expect(page).to have_selector("a[aria-selected=true]", text: "Active")

      within "#active table" do
        within "tbody tr:nth-child(2)" do
          expect(page).to have_selector("td:nth-child(1)", text: "New Token")
          expect(page).to have_selector("td:nth-child(2)", text: "Service Name")
          expect(page).to have_selector("td:nth-child(3)", text: "–")
        end
      end
    end
  end

  context "with basic authentication" do
    it "allows a token to be created" do
      visit "/admin/tokens"

      expect(page).to have_selector("h1", text: "API tokens")
      expect(page).to have_selector("a[aria-selected=true]", text: "Active")

      click_link "Add API token"
      expect(page).to have_selector("h1", text: "Add API token")

      fill_in "Name", with: "New Token"
      fill_in "Service", with: "Service Name"
      check "comment:read"

      within_fieldset "Authentication for downloading documents" do
        choose "Username and password"
      end

      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "Document download authentication has problems")

      within_fieldset "Authentication for downloading documents" do
        expect(page).to have_selector("p.govuk-error-message", text: "Please enter the username")
        expect(page).to have_selector("p.govuk-error-message", text: "Please enter the password")

        fill_in "Username", with: "Username"
        fill_in "Password", with: "Password"
      end

      click_button "Save"
      expect(page).to have_current_path("/admin/tokens")
      expect(page).to have_selector("h1", text: "API token generated")
      expect(page).to have_selector("div.govuk-panel__body strong", text: /\Abops_[a-zA-Z0-9]{36}[-_a-zA-Z0-9]{6}\z/)

      click_link "Return to the list of API tokens"
      expect(page).to have_selector("h1", text: "API tokens")
      expect(page).to have_selector("a[aria-selected=true]", text: "Active")

      within "#active table" do
        within "tbody tr:nth-child(2)" do
          expect(page).to have_selector("td:nth-child(1)", text: "New Token")
          expect(page).to have_selector("td:nth-child(2)", text: "Service Name")
          expect(page).to have_selector("td:nth-child(3)", text: "–")
        end
      end
    end
  end

  context "with bearer authentication" do
    it "allows a token to be created" do
      visit "/admin/tokens"

      expect(page).to have_selector("h1", text: "API tokens")
      expect(page).to have_selector("a[aria-selected=true]", text: "Active")

      click_link "Add API token"
      expect(page).to have_selector("h1", text: "Add API token")

      fill_in "Name", with: "New Token"
      fill_in "Service", with: "Service Name"
      check "comment:read"

      within_fieldset "Authentication for downloading documents" do
        choose "Bearer token"
      end

      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "Document download authentication has problems")

      within_fieldset "Authentication for downloading documents" do
        expect(page).to have_selector("p.govuk-error-message", text: "Please enter the bearer token value")

        fill_in "Token value", with: "thisisasecret"
      end

      click_button "Save"
      expect(page).to have_current_path("/admin/tokens")
      expect(page).to have_selector("h1", text: "API token generated")
      expect(page).to have_selector("div.govuk-panel__body strong", text: /\Abops_[a-zA-Z0-9]{36}[-_a-zA-Z0-9]{6}\z/)

      click_link "Return to the list of API tokens"
      expect(page).to have_selector("h1", text: "API tokens")
      expect(page).to have_selector("a[aria-selected=true]", text: "Active")

      within "#active table" do
        within "tbody tr:nth-child(2)" do
          expect(page).to have_selector("td:nth-child(1)", text: "New Token")
          expect(page).to have_selector("td:nth-child(2)", text: "Service Name")
          expect(page).to have_selector("td:nth-child(3)", text: "–")
        end
      end
    end
  end

  context "with header authentication" do
    it "allows a token to be created" do
      visit "/admin/tokens"

      expect(page).to have_selector("h1", text: "API tokens")
      expect(page).to have_selector("a[aria-selected=true]", text: "Active")

      click_link "Add API token"
      expect(page).to have_selector("h1", text: "Add API token")

      fill_in "Name", with: "New Token"
      fill_in "Service", with: "Service Name"
      check "comment:read"

      within_fieldset "Authentication for downloading documents" do
        choose "Custom header"
      end

      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "Document download authentication has problems")

      within_fieldset "Authentication for downloading documents" do
        expect(page).to have_selector("p.govuk-error-message", text: "Please enter the name of the custom header")
        expect(page).to have_selector("p.govuk-error-message", text: "Please enter the value for the custom header")

        fill_in "Header name", with: "api-key"
        fill_in "Header value", with: "thisisasecret"
      end

      click_button "Save"
      expect(page).to have_current_path("/admin/tokens")
      expect(page).to have_selector("h1", text: "API token generated")
      expect(page).to have_selector("div.govuk-panel__body strong", text: /\Abops_[a-zA-Z0-9]{36}[-_a-zA-Z0-9]{6}\z/)

      click_link "Return to the list of API tokens"
      expect(page).to have_selector("h1", text: "API tokens")
      expect(page).to have_selector("a[aria-selected=true]", text: "Active")

      within "#active table" do
        within "tbody tr:nth-child(2)" do
          expect(page).to have_selector("td:nth-child(1)", text: "New Token")
          expect(page).to have_selector("td:nth-child(2)", text: "Service Name")
          expect(page).to have_selector("td:nth-child(3)", text: "–")
        end
      end
    end
  end
end
