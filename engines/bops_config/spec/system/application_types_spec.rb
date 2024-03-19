# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Application Types", type: :system, bops_config: true do
  let(:user) { create(:user, :global_administrator, name: "Clark Kent", local_authority: nil) }

  before do
    sign_in(user)
    visit "/"
  end

  it "allows adding a new application type" do
    visit "/application_types/new"
    expect(page).to have_selector("h1", text: "Application profile")

    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "Select an application type name")
    expect(page).to have_selector("[role=alert] li", text: "Enter a suffix for the application number")

    fill_in "Name", with: "Planning Permission - Major application"
    fill_in "Suffix", with: "MAJR"

    click_button "Continue"
    # Set determination period
    expect(page).to have_selector("h1", text: "Set determination period")
    expect(page).to have_selector("p.govuk-hint", text: "Choose the length of the determination period for this type of application.")

    fill_in "application_type[determination_period_days]", with: "not an integer"
    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "Determination period days is not a number")

    fill_in "application_type[determination_period_days]", with: "0"
    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "Determination period days must be greater than or equal to 1")

    fill_in "application_type[determination_period_days]", with: "100"
    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "Determination period days must be less than or equal to 99")

    fill_in "application_type[determination_period_days]", with: "25"
    click_button "Continue"
    expect(page).to have_content("Determination period successfully updated")

    # Review application type
    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(1) dd", text: "Planning Permission - Major application")
    expect(page).to have_selector("dl div:nth-child(2) dd", text: "MAJR")
    expect(page).to have_selector("dl div:nth-child(3) dd", text: "25 days - bank holidays included")
    expect(page).to have_selector("dl div:nth-child(4) dd", text: "Inactive")
  end

  it "allows editing of an inactive application type" do
    application_type = create(:application_type, :ldc_proposed, status: "inactive")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(1)" do
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Application profile")

    fill_in "Name", with: "Lawful Development Certificate - Existing use"
    fill_in "Suffix", with: "LDCE"

    click_button "Continue"
    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(1) dd", text: "Lawful Development Certificate - Existing use")
    expect(page).to have_selector("dl div:nth-child(2) dd", text: "LDCE")
  end

  it "prevents editing of an active application type" do
    application_type = create(:application_type, :ldc_proposed, status: "active")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(1)" do
      expect(page).not_to have_link("Change")
    end

    within "dl div:nth-child(2)" do
      expect(page).not_to have_link("Change")
    end

    visit "/application_types/#{application_type.id}/edit"
    expect(page).to have_selector("h1", text: "Application profile")

    fill_in "Name", with: "Lawful Development Certificate - Existing use"
    fill_in "Suffix", with: "LDCE"

    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "The name can't be changed when the application type is active")
    expect(page).to have_selector("[role=alert] li", text: "The suffix can't be changed when the application type is active")
  end

  it "prevents editing of a retired application type" do
    application_type = create(:application_type, :ldc_proposed, status: "retired")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(1)" do
      expect(page).not_to have_link("Change")
    end

    within "dl div:nth-child(2)" do
      expect(page).not_to have_link("Change")
    end

    visit "/application_types/#{application_type.id}/edit"
    expect(page).to have_selector("h1", text: "Application profile")

    fill_in "Name", with: "Lawful Development Certificate - Existing use"
    fill_in "Suffix", with: "LDCE"

    click_button "Continue"
    expect(page).to have_selector("[role=alert] li", text: "The name can't be changed when the application type is retired")
    expect(page).to have_selector("[role=alert] li", text: "The suffix can't be changed when the application type is retired")
  end

  it "allows activation of a new application type" do
    application_type = create(:application_type, :ldc_proposed, status: "inactive")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(4)" do
      expect(page).to have_selector("dd", text: "Inactive")
      click_link "Edit"
    end

    expect(page).to have_selector("h1", text: "Update status")

    choose "Active"
    click_button "Continue"

    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(4) dd", text: "Active")
  end

  it "allows retirement of an application type" do
    application_type = create(:application_type, :ldc_proposed, status: "active")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(4)" do
      expect(page).to have_selector("dd", text: "Active")
      click_link "Edit"
    end

    expect(page).to have_selector("h1", text: "Update status")
    expect(page).to have_no_field("Inactive")

    choose "Retired"
    click_button "Continue"

    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(4) dd", text: "Retired")
  end

  it "allows an application type to be brought out of retirement" do
    application_type = create(:application_type, :ldc_proposed, status: "retired")

    visit "/application_types/#{application_type.id}"
    expect(page).to have_selector("h1", text: "Review the application type")

    within "dl div:nth-child(4)" do
      expect(page).to have_selector("dd", text: "Retired")
      click_link "Edit"
    end

    expect(page).to have_selector("h1", text: "Update status")
    expect(page).to have_no_field("Inactive")

    choose "Active"
    click_button "Continue"

    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(4) dd", text: "Active")
  end

  it "allows editing of the determination period days" do
    application_type = create(:application_type, :ldc_proposed, determination_period_days: 25)

    visit "/application_types/#{application_type.id}"

    within "dl div:nth-child(3)" do
      click_link "Change"
    end

    expect(page).to have_selector("h1", text: "Set determination period")

    fill_in "application_type[determination_period_days]", with: "35"
    click_button "Continue"

    expect(page).to have_content("Determination period successfully updated")
    expect(page).to have_selector("h1", text: "Review the application type")
    expect(page).to have_selector("dl div:nth-child(3) dd", text: "35 days - bank holidays included")
  end

  it "displays application types" do
    ldc_existing = create(:application_type, :ldc_existing, status: "active")
    ldc_proposed = create(:application_type, :ldc_proposed, status: "retired")
    prior_approval = create(:application_type, :prior_approval, status: "active")
    planning_permission = create(:application_type, :planning_permission, status: "inactive")

    visit "/application_types"
    expect(page).to have_selector("h1", text: "Application Types")

    expect(page).to have_link(
      "Create new application type",
      href: "/application_types/new"
    )

    within(".govuk-table.application-types-table") do
      within "thead > tr:first-child" do
        expect(page).to have_selector("th:nth-child(1)", text: "Suffix")
        expect(page).to have_selector("th:nth-child(2)", text: "Application type")
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
              href: "/application_types/#{prior_approval.id}"
            )
          end
        end

        within "tr:nth-child(2)" do
          expect(page).to have_selector("td:nth-child(1)", text: "HAPP")
          expect(page).to have_selector("td:nth-child(2)", text: "Planning Permission - Full householder")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--grey", text: "Inactive")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/application_types/#{planning_permission.id}"
            )
          end
        end

        within "tr:nth-child(3)" do
          expect(page).to have_selector("td:nth-child(1)", text: "LDCE")
          expect(page).to have_selector("td:nth-child(2)", text: "Lawful Development Certificate - Existing use")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--green", text: "Active")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/application_types/#{ldc_existing.id}"
            )
          end
        end

        within "tr:nth-child(4)" do
          expect(page).to have_selector("td:nth-child(1)", text: "LDCP")
          expect(page).to have_selector("td:nth-child(2)", text: "Lawful Development Certificate - Proposed use")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--red", text: "Retired")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/application_types/#{ldc_proposed.id}"
            )
          end
        end
      end
    end
  end
end
