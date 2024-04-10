# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe "Reporting types", type: :system do
  let!(:user) { create(:user, :global_administrator, name: "Clark Kent", local_authority: nil) }
  let!(:reporting_type) { create(:reporting_type, :prior_approval_1a) }
  let!(:application_type) { create(:application_type, :prior_approval) }

  before do
    sign_in(user)
    visit "/"
  end

  it "allows viewing of reporting types" do
    click_link "Reporting types"

    expect(page).to have_selector("h1", text: "Reporting Types")
    expect(page).to have_link("Create reporting type", href: "/reporting_types/new")

    within "table" do
      within "thead tr" do
        expect(page).to have_selector("th:nth-child(1)", text: "Code")
        expect(page).to have_selector("th:nth-child(2)", text: "Description")
        expect(page).to have_selector("th:nth-child(3)", text: "Category")
        expect(page).to have_selector("th:nth-child(4)", text: "Action")
      end

      within "tbody tr:nth-child(1)" do
        expect(page).to have_selector("td:nth-child(1)", text: "PA1")
        expect(page).to have_selector("td:nth-child(2)", text: "Larger householder extensions")
        expect(page).to have_selector("td:nth-child(3)", text: "Prior Approval")

        within "td:nth-child(4)" do
          expect(page).to have_link("Edit", href: "/reporting_types/#{reporting_type.id}/edit")
        end
      end
    end
  end

  it "allows creation of reporting types" do
    click_link "Reporting types"
    expect(page).to have_selector("h1", text: "Reporting Types")

    click_link "Create reporting type"
    expect(page).to have_selector("h1", text: "Create reporting type")

    click_button "Save"
    expect(page).to have_selector("[role=alert] li", text: "Enter a code for this reporting type")
    expect(page).to have_selector("[role=alert] li", text: "Choose at least one category for this reporting type")
    expect(page).to have_selector("[role=alert] li", text: "Enter a description for this reporting type")

    fill_in "Description", with: "All others"
    fill_in "Code", with: "PA99"
    check "Prior Approval"

    click_button "Save"
    expect(page).to have_selector("[role=alert] li", text: "Enter the legislation for prior approval reporting types")

    fill_in "Legislation", with: "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2"

    click_button "Save"
    expect(page).to have_content("Reporting type successfully created")

    within "table" do
      within "tbody tr:nth-child(2)" do
        expect(page).to have_selector("td:nth-child(1)", text: "PA99")
        expect(page).to have_selector("td:nth-child(2)", text: "All others")
        expect(page).to have_selector("td:nth-child(3)", text: "Prior Approval")
        expect(page).to have_selector("td:nth-child(4) a", text: "Edit")
      end
    end
  end

  it "allows creation of reporting types that apply to multiple categories" do
    click_link "Reporting types"
    expect(page).to have_selector("h1", text: "Reporting Types")

    click_link "Create reporting type"
    expect(page).to have_selector("h1", text: "Create reporting type")

    fill_in "Description", with: "Dwellings (major)"
    fill_in "Code", with: "Q01"
    check "Full Planning Permission"
    check "Outline Planning Permission"

    click_button "Save"
    expect(page).to have_content("Reporting type successfully created")

    within "table" do
      within "tbody tr:nth-child(2)" do
        expect(page).to have_selector("td:nth-child(1)", text: "Q01")
        expect(page).to have_selector("td:nth-child(2)", text: "Dwellings (major)")

        within "td:nth-child(3)" do
          expect(page).to have_selector("li:nth-child(1)", text: "Full Planning Permission")
          expect(page).to have_selector("li:nth-child(2)", text: "Outline Planning Permission")
        end

        expect(page).to have_selector("td:nth-child(4) a", text: "Edit")
      end
    end
  end

  it "allows editing of reporting types" do
    create(:reporting_type, :prior_approval_all_others)

    click_link "Reporting types"
    expect(page).to have_selector("h1", text: "Reporting Types")

    within "table" do
      within "tbody tr:nth-child(2)" do
        expect(page).to have_selector("td:nth-child(1)", text: "PA99")
        expect(page).to have_selector("td:nth-child(2)", text: "All others")
        expect(page).to have_selector("td:nth-child(3)", text: "Prior Approval")
        expect(page).to have_selector("td:nth-child(4) a", text: "Edit")

        click_link "Edit"
      end
    end

    expect(page).to have_selector("h1", text: "Edit reporting type")

    fill_in "Description", with: "All other prior approvals"
    click_button "Save"

    expect(page).to have_content("Reporting type successfully updated")

    within "table" do
      within "tbody tr:nth-child(2)" do
        expect(page).to have_selector("td:nth-child(1)", text: "PA99")
        expect(page).to have_selector("td:nth-child(2)", text: "All other prior approvals")
        expect(page).to have_selector("td:nth-child(3)", text: "Prior Approval")
        expect(page).to have_selector("td:nth-child(4) a", text: "Edit")
      end
    end
  end

  it "allows removal of reporting types" do
    create(:reporting_type, :prior_approval_all_others)

    click_link "Reporting types"
    expect(page).to have_selector("h1", text: "Reporting Types")

    within "table" do
      within "tbody tr:nth-child(2)" do
        expect(page).to have_selector("td:nth-child(1)", text: "PA99")
        expect(page).to have_selector("td:nth-child(2)", text: "All others")
        expect(page).to have_selector("td:nth-child(3)", text: "Prior Approval")
        expect(page).to have_selector("td:nth-child(4) a", text: "Edit")

        click_link "Edit"
      end
    end

    expect(page).to have_selector("h1", text: "Edit reporting type")

    accept_confirm do
      click_link "Remove"
    end

    expect(page).to have_content("Reporting type successfully removed")
    expect(page).not_to have_selector("table tbody tr:nth-child(2)")
  end

  it "doesn't allow removal of reporting types when they're used" do
    click_link "Reporting types"
    expect(page).to have_selector("h1", text: "Reporting Types")

    within "table" do
      within "tbody tr:nth-child(1)" do
        expect(page).to have_selector("td:nth-child(1)", text: "PA1")
        expect(page).to have_selector("td:nth-child(2)", text: "Larger householder extensions")
        expect(page).to have_selector("td:nth-child(3)", text: "Prior Approval")
        expect(page).to have_selector("td:nth-child(4) a", text: "Edit")

        click_link "Edit"
      end
    end

    expect(page).to have_selector("h1", text: "Edit reporting type")

    accept_confirm do
      click_link "Remove"
    end

    expect(page).to have_selector("[role=alert] li", text: "You can't remove a reporting type that's being used by an application type")
  end
end
