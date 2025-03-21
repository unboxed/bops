# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profile", type: :system do
  let(:local_authority) { create(:local_authority, :default, :with_api_user) }
  let(:application_type) { create(:application_type, code: "preApp", determination_period_days: 30, local_authority:) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "shows the council as active on the dashboard" do
    visit "/admin/dashboard"
    expect(page).to have_content("Active")
  end

  it "allows the administrator to view the determination period days" do
    pre_application = create(:application_type, :pre_application, status: "active", local_authority:)
    ldc_existing = create(:application_type, :ldc_existing, status: "active", local_authority:)
    ldc_proposed = create(:application_type, :ldc_proposed, status: "retired", local_authority:)
    prior_approval = create(:application_type, :prior_approval, status: "active", local_authority:)
    planning_permission = create(:application_type, :planning_permission, status: "inactive", local_authority:)

    visit "/admin/application_types"

    within("#active table") do
      within "thead > tr:first-child" do
        expect(page).to have_selector("th:nth-child(1)", text: "Suffix")
        expect(page).to have_selector("th:nth-child(2)", text: "Name")
        expect(page).to have_selector("th:nth-child(3)", text: "Status")
        expect(page).to have_selector("th:nth-child(4)", text: "Action")
      end

      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "PA")
          expect(page).to have_selector("td:nth-child(2)", text: "Prior Approval - Larger extension to a house")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--green", text: "Active")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/admin/application_types/#{prior_approval.id}"
            )
          end
        end

        within "tr:nth-child(2)" do
          expect(page).to have_selector("td:nth-child(1)", text: "LDCE")
          expect(page).to have_selector("td:nth-child(2)", text: "Lawful Development Certificate - Existing use")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--green", text: "Active")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/admin/application_types/#{ldc_existing.id}"
            )
          end
        end

        within "tr:nth-child(2)" do
          expect(page).to have_selector("td:nth-child(1)", text: "LDCE")
          expect(page).to have_selector("td:nth-child(2)", text: "Lawful Development Certificate - Existing use")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--green", text: "Active")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/admin/application_types/#{ldc_existing.id}"
            )
          end
        end

        within "tr:nth-child(3)" do
          expect(page).to have_selector("td:nth-child(1)", text: "PRE")
          expect(page).to have_selector("td:nth-child(2)", text: "Pre-application Advice")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--green", text: "Active")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/admin/application_types/#{pre_application.id}"
            )
          end
        end
      end
    end

    within("#inactive table") do
      within "thead > tr:first-child" do
        expect(page).to have_selector("th:nth-child(1)", text: "Suffix")
        expect(page).to have_selector("th:nth-child(2)", text: "Name")
        expect(page).to have_selector("th:nth-child(3)", text: "Status")
        expect(page).to have_selector("th:nth-child(4)", text: "Action")
      end

      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "HAPP")
          expect(page).to have_selector("td:nth-child(2)", text: "Planning Permission - Full householder")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--grey", text: "Inactive")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/admin/application_types/#{planning_permission.id}"
            )
          end
        end
      end
    end

    within("#retired table") do
      within "thead > tr:first-child" do
        expect(page).to have_selector("th:nth-child(1)", text: "Suffix")
        expect(page).to have_selector("th:nth-child(2)", text: "Name")
        expect(page).to have_selector("th:nth-child(3)", text: "Status")
        expect(page).to have_selector("th:nth-child(4)", text: "Action")
      end

      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "LDCP")
          expect(page).to have_selector("td:nth-child(2)", text: "Lawful Development Certificate - Proposed use")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--red", text: "Retired")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/admin/application_types/#{ldc_proposed.id}"
            )
          end
        end
      end
    end
  end

  it "allows the administrator to edit the determination period days" do
    application_type = create(:application_type, :configured, :pre_application, determination_period_days: 30, local_authority:)

    visit "/admin/application_types/#{application_type.id}"

    within "dl div:nth-child(6)" do
      expect(page).to have_selector("dd", text: "30 days - bank holidays included")
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Set determination period")
    expect(page).to have_selector("h1 > span", text: "Pre-application Advice")

    # Set determination period
    expect(page).to have_selector(".govuk-label", text: "Set determination period")
    expect(page).to have_selector("div.govuk-hint", text: "Choose the length of the determination period for this type of application.")

    fill_in "Set determination period", with: ""
    click_button "Continue"

    expect(page).to have_content("can't be blank")

    fill_in "Set determination period", with: "not an integer"
    click_button "Continue"

    expect(page).to have_content("is not a number")

    fill_in "Set determination period", with: "1.1"
    click_button "Continue"

    expect(page).to have_content("must be an integer")

    fill_in "Set determination period", with: "0"
    click_button "Continue"
    expect(page).to have_content("must be greater than or equal to 1")

    fill_in "Set determination period", with: "100"
    click_button "Continue"
    expect(page).to have_content("must be less than or equal to 99")

    fill_in "Set determination period", with: "25"
    click_button "Continue"

    expect(page).to have_content("Determination period successfully updated")
    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(6) dd", text: "25 days - bank holidays included")
  end

  it "allows the administrator to edit the disclaimer" do
    application_type = create(:application_type, :configured, :pre_application, local_authority:)

    visit "/admin/application_types/#{application_type.id}"

    within "dl div:nth-child(7)" do
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Set disclaimer")
    expect(page).to have_selector("h1 > span", text: "Pre-application Advice")

    # Set determination period
    expect(page).to have_selector(".govuk-label", text: "Set disclaimer")
    expect(page).to have_selector("div.govuk-hint", text: "Set the legal disclaimer that will be displayed for this type of application.")

    fill_in "Set disclaimer", with: "hello world!"
    click_button "Continue"

    expect(page).to have_content("Disclaimer successfully updated")
    expect(page).to have_content("hello world!")

    within "dl div:nth-child(7)" do
      click_link "Change"
    end

    fill_in "Set disclaimer", with: ""
    click_button "Continue"

    expect(page).to have_content("Disclaimer successfully updated")
    expect(page).not_to have_content("hello world!")

    expect(page).to have_selector("h1", text: "Review the application type")
  end
end
